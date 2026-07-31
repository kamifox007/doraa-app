-- ══════════════════════════════════════════════════════════════
-- نظام الاشتراك الشهري + المحفظة الرقمية
-- DORA App - Driver Subscription & Wallet System
-- ══════════════════════════════════════════════════════════════

-- إضافة أعمدة الاشتراك والمحفظة لجدول user_profiles
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS subscription_expiry  TIMESTAMPTZ  DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS wallet_balance        NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_subscription_active BOOLEAN     DEFAULT FALSE;

-- ══════════════════════════════════════════════════════════════
-- جدول سجل المعاملات (عمولات + اشتراكات + شحن)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID            REFERENCES auth.users(id) ON DELETE CASCADE,
  type          TEXT            NOT NULL CHECK (type IN ('commission', 'subscription', 'topup', 'refund')),
  amount        NUMERIC(10,2)   NOT NULL,   -- موجب = إضافة، سالب = خصم
  description   TEXT,
  ride_id       UUID            DEFAULT NULL,
  created_at    TIMESTAMPTZ     DEFAULT now()
);

-- تفعيل الـ RLS
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can view own transactions"
  ON wallet_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- المشرف يمكنه إضافة معاملات (شحن يدوي)
CREATE POLICY "admins can insert transactions"
  ON wallet_transactions FOR INSERT
  WITH CHECK (true);  -- يُضبط لاحقاً حسب دور المشرف

-- ══════════════════════════════════════════════════════════════
-- دالة خصم العمولة تلقائياً عند اكتمال الرحلة
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION deduct_commission(
  p_user_id   UUID,
  p_ride_id   UUID,
  p_fare      NUMERIC
)
RETURNS void AS $$
DECLARE
  commission NUMERIC;
BEGIN
  commission := ROUND(p_fare * 0.10, 2); -- 10% عمولة DORA

  -- خصم من رصيد المحفظة
  UPDATE user_profiles
    SET wallet_balance = wallet_balance - commission
  WHERE user_id = p_user_id;

  -- تسجيل المعاملة
  INSERT INTO wallet_transactions (user_id, type, amount, description, ride_id)
  VALUES (p_user_id, 'commission', -commission, 'عمولة DORA 10%', p_ride_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════════════════════════
-- دالة تجديد الاشتراك (تُستدعى من لوحة المشرف)
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION renew_subscription(
  p_user_id UUID,
  p_months  INT DEFAULT 1
)
RETURNS void AS $$
DECLARE
  current_expiry TIMESTAMPTZ;
  new_expiry     TIMESTAMPTZ;
  fee            NUMERIC := 3000 * p_months;
BEGIN
  SELECT subscription_expiry INTO current_expiry
    FROM user_profiles WHERE user_id = p_user_id;

  -- إذا كان الاشتراك منتهياً، يبدأ من الآن
  IF current_expiry IS NULL OR current_expiry < now() THEN
    new_expiry := now() + (p_months || ' months')::INTERVAL;
  ELSE
    new_expiry := current_expiry + (p_months || ' months')::INTERVAL;
  END IF;

  UPDATE user_profiles
    SET subscription_expiry = new_expiry,
        is_subscription_active = TRUE
  WHERE user_id = p_user_id;

  INSERT INTO wallet_transactions (user_id, type, amount, description)
  VALUES (p_user_id, 'subscription', -fee, 'اشتراك شهري DORA - ' || p_months || ' شهر/أشهر');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════════════════════════
-- دالة شحن المحفظة (تُستدعى من لوحة المشرف بعد استلام بريدي موب)
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION topup_wallet(
  p_user_id UUID,
  p_amount  NUMERIC
)
RETURNS void AS $$
BEGIN
  UPDATE user_profiles
    SET wallet_balance = wallet_balance + p_amount
  WHERE user_id = p_user_id;

  INSERT INTO wallet_transactions (user_id, type, amount, description)
  VALUES (p_user_id, 'topup', p_amount, 'شحن المحفظة - بريدي موب');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
