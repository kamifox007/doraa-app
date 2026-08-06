-- ══════════════════════════════════════════════════════════════
-- الحساب الآلي الذكي للعمولة - DORA Smart Commission Engine
-- ══════════════════════════════════════════════════════════════
-- المنطق:
--   1. الشهر الأول مجاني (لا عمولة)
--   2. اشتراك نشط = لا عمولة
--   3. إذا يوجد رصيد إحالة في المحفظة → تُقتطع العمولة منه أولاً
--   4. بعد نفاد رصيد الإحالة → تُقتطع العمولة من أرباح الرحلة
-- ══════════════════════════════════════════════════════════════

-- جدول المحافظ (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.wallets (
  id            uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       uuid        NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  balance       numeric     NOT NULL DEFAULT 0 CHECK (balance >= 0),
  -- رصيد خاص مشحون من مكافآت الإحالة
  referral_credit numeric   NOT NULL DEFAULT 0 CHECK (referral_credit >= 0),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ride_id     uuid,
  type        text        NOT NULL CHECK (type IN ('topup','commission','commission_from_credit','referral_bonus','promo','withdrawal')),
  amount      numeric     NOT NULL,
  description text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ══════════════════════════════════════════════════════════════
-- الدالة الرئيسية: deduct_commission_smart
-- تُستدعى تلقائياً عند اكتمال كل رحلة
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.deduct_commission_smart(
  p_user_id   uuid,
  p_ride_id   uuid,
  p_fare      numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_created_at      timestamptz;
  v_expiry          timestamptz;
  v_referral_credit numeric := 0;
  v_commission      numeric := 0;
  v_from_credit     numeric := 0;
  v_from_earnings   numeric := 0;
  is_free           boolean := false;
BEGIN
  -- 1. جلب بيانات السائقة
  SELECT created_at, subscription_expiry
  INTO v_created_at, v_expiry
  FROM public.user_profiles
  WHERE user_id = p_user_id;

  -- 2. التحقق من الشهر الأول المجاني (30 يوماً)
  IF v_created_at IS NOT NULL AND v_created_at + INTERVAL '30 days' > now() THEN
    is_free := true;
  END IF;

  -- 3. التحقق من وجود اشتراك نشط
  IF v_expiry IS NOT NULL AND v_expiry > now() THEN
    is_free := true;
  END IF;

  -- لا عمولة → خروج مبكر
  IF is_free THEN
    RETURN jsonb_build_object(
      'commission', 0,
      'from_credit', 0,
      'from_earnings', 0,
      'reason', 'free_period_or_subscription'
    );
  END IF;

  -- 4. حساب العمولة 10%
  v_commission := ROUND(p_fare * 0.10, 2);

  -- 5. جلب رصيد الإحالة المشحون في المحفظة
  SELECT coalesce(referral_credit, 0)
  INTO v_referral_credit
  FROM public.wallets
  WHERE user_id = p_user_id;

  -- ══════════════════════════════════════════
  -- 💡 الحساب الآلي الذكي:
  -- العمولة تُقتطع من رصيد الإحالة أولاً
  -- ══════════════════════════════════════════
  IF v_referral_credit >= v_commission THEN
    -- ✅ رصيد الإحالة يكفي → اقتطع كل العمولة منه
    v_from_credit   := v_commission;
    v_from_earnings := 0;

    UPDATE public.wallets
    SET referral_credit = referral_credit - v_from_credit,
        updated_at      = now()
    WHERE user_id = p_user_id;

    INSERT INTO public.wallet_transactions (user_id, ride_id, type, amount, description)
    VALUES (p_user_id, p_ride_id, 'commission_from_credit', -v_from_credit,
            'عمولة 10% مدفوعة من رصيد مكافأة الإحالة 🎁');

  ELSIF v_referral_credit > 0 THEN
    -- ⚠️ رصيد الإحالة يكفي جزئياً
    v_from_credit   := v_referral_credit;
    v_from_earnings := v_commission - v_from_credit;

    -- اسحب ما تبقى من رصيد الإحالة أولاً
    UPDATE public.wallets
    SET referral_credit = 0,
        balance         = balance - v_from_earnings,
        updated_at      = now()
    WHERE user_id = p_user_id;

    INSERT INTO public.wallet_transactions (user_id, ride_id, type, amount, description)
    VALUES (p_user_id, p_ride_id, 'commission_from_credit', -v_from_credit,
            'عمولة جزئية من رصيد الإحالة (نفد الرصيد)');

    INSERT INTO public.wallet_transactions (user_id, ride_id, type, amount, description)
    VALUES (p_user_id, p_ride_id, 'commission', -v_from_earnings,
            'عمولة 10% (تكملة من الأرباح بعد نفاد رصيد الإحالة)');

  ELSE
    -- ❌ لا رصيد إحالة → عمولة طبيعية من الأرباح
    v_from_credit   := 0;
    v_from_earnings := v_commission;

    UPDATE public.wallets
    SET balance    = balance - v_from_earnings,
        updated_at = now()
    WHERE user_id = p_user_id;

    INSERT INTO public.wallet_transactions (user_id, ride_id, type, amount, description)
    VALUES (p_user_id, p_ride_id, 'commission', -v_from_earnings,
            'عمولة رحلة 10%');
  END IF;

  RETURN jsonb_build_object(
    'commission',     v_commission,
    'from_credit',    v_from_credit,
    'from_earnings',  v_from_earnings,
    'credit_remaining', GREATEST(0, v_referral_credit - v_from_credit)
  );
END;
$$;

-- ══════════════════════════════════════════════════════════════
-- شحن مكافأة الإحالة كـ referral_credit (وليس balance عادي)
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.add_referral_credit(p_user_id uuid, p_amount numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- إنشاء محفظة إن لم تكن موجودة
  INSERT INTO public.wallets (user_id, referral_credit)
  VALUES (p_user_id, p_amount)
  ON CONFLICT (user_id)
  DO UPDATE SET referral_credit = wallets.referral_credit + p_amount,
               updated_at       = now();

  -- تسجيل المعاملة
  INSERT INTO public.wallet_transactions (user_id, type, amount, description)
  VALUES (p_user_id, 'referral_bonus', p_amount,
          'رصيد مكافأة إحالة DORA 🎁 - يُستخدم تلقائياً لدفع عمولة رحلاتك القادمة');
END;
$$;

-- ══════════════════════════════════════════════════════════════
-- دالة: عرض ملخص المحفظة الذكي للسائقة
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_wallet_summary(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance        numeric := 0;
  v_credit         numeric := 0;
  v_total_earned   numeric := 0;
  v_total_paid     numeric := 0;
  v_rides_covered  int     := 0;
BEGIN
  SELECT coalesce(balance,0), coalesce(referral_credit,0)
  INTO v_balance, v_credit
  FROM public.wallets WHERE user_id = p_user_id;

  SELECT coalesce(sum(amount),0)
  INTO v_total_earned
  FROM public.wallet_transactions
  WHERE user_id = p_user_id AND amount > 0;

  SELECT coalesce(sum(abs(amount)),0)
  INTO v_total_paid
  FROM public.wallet_transactions
  WHERE user_id = p_user_id AND type IN ('commission','commission_from_credit');

  -- عدد الرحلات التي غطى فيها الرصيد العمولة
  SELECT count(*)
  INTO v_rides_covered
  FROM public.wallet_transactions
  WHERE user_id = p_user_id AND type = 'commission_from_credit';

  RETURN jsonb_build_object(
    'balance',          v_balance,
    'referral_credit',  v_credit,
    'total_earned',     v_total_earned,
    'total_commission_paid', v_total_paid,
    'rides_covered_by_credit', v_rides_covered
  );
END;
$$;
