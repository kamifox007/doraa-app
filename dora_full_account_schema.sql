-- ══════════════════════════════════════════════════════════════════════
-- DORA - Full Account Data Schema
-- كل مستخدمة لها حسابها الكامل المستقل
-- جدول موحد يسحب كل شيء: المحفظة، العمولات، الإحالات، الاشتراك
-- ══════════════════════════════════════════════════════════════════════

-- ── 1. جداول البيانات الأساسية ──────────────────────────────────────

-- ملف الحساب الشخصي (موجود مسبقاً)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id                   uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              uuid        NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name            text,
  phone                text,
  role                 text        NOT NULL DEFAULT 'rider' CHECK (role IN ('rider','driver','pending_driver','admin')),
  avatar_url           text,
  wallet_balance       numeric     NOT NULL DEFAULT 0,
  subscription_expiry  timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

-- محافظ المستخدمين (رصيد + رصيد إحالة)
CREATE TABLE IF NOT EXISTS public.wallets (
  id               uuid    DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          uuid    NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  balance          numeric NOT NULL DEFAULT 0 CHECK (balance >= 0),
  referral_credit  numeric NOT NULL DEFAULT 0 CHECK (referral_credit >= 0),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- سجل المعاملات المالية لكل مستخدمة
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ride_id     uuid,
  type        text        NOT NULL CHECK (type IN (
                'topup',             -- شحن
                'commission',        -- عمولة عادية من الأرباح
                'commission_from_credit', -- عمولة من رصيد الإحالة
                'referral_bonus',    -- مكافأة إحالة
                'promo',             -- عرض ترويجي
                'withdrawal'         -- سحب
              )),
  amount      numeric     NOT NULL,
  description text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- إحالات (سائقات + ركاب)
CREATE TABLE IF NOT EXISTS public.referrals (
  id            uuid    DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id   uuid    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_id   uuid    REFERENCES auth.users(id) ON DELETE SET NULL,
  referral_code text    NOT NULL UNIQUE,
  referral_type text    NOT NULL DEFAULT 'driver' CHECK (referral_type IN ('driver','rider')),
  status        text    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','completed')),
  reward_amount numeric NOT NULL DEFAULT 1000,
  reward_paid   boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  completed_at  timestamptz
);

-- خصومات الراكبات (5 ركاب محالين = 20% خصم)
CREATE TABLE IF NOT EXISTS public.rider_discounts (
  id           uuid    DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  discount_pct int     NOT NULL DEFAULT 20,
  is_used      boolean NOT NULL DEFAULT false,
  ride_id      uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  used_at      timestamptz,
  expires_at   timestamptz NOT NULL DEFAULT (now() + interval '90 days')
);

-- ── 2. فهارس للبحث السريع ───────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_wallets_user_id              ON public.wallets (user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_user_id           ON public.wallet_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_created_at        ON public.wallet_transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id        ON public.referrals (referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referral_code      ON public.referrals (referral_code);
CREATE INDEX IF NOT EXISTS idx_rider_discounts_user_id      ON public.rider_discounts (user_id);

-- ══════════════════════════════════════════════════════════════════════
-- الدالة الرئيسية: get_full_account_summary
-- تسحب كل شيء لأي مستخدمة بـ user_id واحد فقط
-- ══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_full_account_summary(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  -- Profile
  v_role              text;
  v_full_name         text;
  v_created_at        timestamptz;
  v_sub_expiry        timestamptz;
  v_is_free_trial     boolean;
  v_is_sub_active     boolean;
  v_days_left         int;

  -- Wallet
  v_balance           numeric := 0;
  v_referral_credit   numeric := 0;

  -- Commissions
  v_total_commission_paid       numeric := 0;
  v_total_commission_from_credit numeric := 0;
  v_rides_covered_by_credit     int := 0;
  v_commission_rate             text;

  -- Referrals - Driver
  v_referral_code     text;
  v_driver_refs_count int := 0;
  v_driver_refs_earned numeric := 0;
  v_has_pending_credit boolean := false;

  -- Referrals - Rider
  v_rider_refs_count  int := 0;
  v_has_ride_discount boolean := false;
  v_ride_discount_pct int := 0;
  v_remaining_for_discount int := 5;

  -- Transactions (last 20)
  v_transactions      jsonb;
BEGIN
  -- ── 1. بيانات الملف الشخصي ──
  SELECT role, full_name, created_at, subscription_expiry
  INTO v_role, v_full_name, v_created_at, v_sub_expiry
  FROM public.user_profiles
  WHERE user_id = p_user_id;

  -- فحص الشهر الأول المجاني
  v_is_free_trial := (v_created_at IS NOT NULL AND v_created_at + interval '30 days' > now());

  -- فحص الاشتراك النشط
  v_is_sub_active := (v_sub_expiry IS NOT NULL AND v_sub_expiry > now());

  -- أيام متبقية
  IF v_is_free_trial THEN
    v_days_left := 30 - EXTRACT(DAY FROM now() - v_created_at)::int;
  ELSIF v_is_sub_active THEN
    v_days_left := EXTRACT(DAY FROM v_sub_expiry - now())::int;
  ELSE
    v_days_left := 0;
  END IF;

  -- نسبة العمولة
  v_commission_rate := CASE WHEN (v_is_free_trial OR v_is_sub_active) THEN '0%' ELSE '10%' END;

  -- ── 2. المحفظة ──
  SELECT coalesce(balance, 0), coalesce(referral_credit, 0)
  INTO v_balance, v_referral_credit
  FROM public.wallets
  WHERE user_id = p_user_id;

  -- ── 3. إحصائيات العمولات ──
  SELECT
    coalesce(sum(abs(amount)) FILTER (WHERE type = 'commission'), 0),
    coalesce(sum(abs(amount)) FILTER (WHERE type = 'commission_from_credit'), 0),
    coalesce(count(*) FILTER (WHERE type = 'commission_from_credit'), 0)
  INTO v_total_commission_paid, v_total_commission_from_credit, v_rides_covered_by_credit
  FROM public.wallet_transactions
  WHERE user_id = p_user_id;

  -- ── 4. إحصائيات الإحالة (كسائقة) ──
  SELECT referral_code INTO v_referral_code
  FROM public.referrals
  WHERE referrer_id = p_user_id AND referred_id IS NULL
  LIMIT 1;

  IF v_referral_code IS NULL THEN
    v_referral_code := upper(substring(replace(p_user_id::text, '-', ''), 1, 8));
    INSERT INTO public.referrals (referrer_id, referral_code)
    VALUES (p_user_id, v_referral_code)
    ON CONFLICT DO NOTHING;
  END IF;

  SELECT
    coalesce(count(*) FILTER (WHERE referral_type = 'driver' AND status = 'completed'), 0),
    coalesce(sum(reward_amount) FILTER (WHERE referral_type = 'driver' AND status = 'completed' AND reward_paid), 0)
  INTO v_driver_refs_count, v_driver_refs_earned
  FROM public.referrals
  WHERE referrer_id = p_user_id;

  -- هل يوجد رصيد إحالة مجمّد (غير مسجلة بعد كسائقة)
  SELECT EXISTS (
    SELECT 1 FROM public.referrals
    WHERE referred_id = p_user_id
      AND referral_type = 'driver'
      AND reward_paid = false
  ) INTO v_has_pending_credit;

  -- ── 5. إحصائيات الإحالة (كراكبة) ──
  SELECT coalesce(count(*) FILTER (WHERE referral_type = 'rider' AND status = 'completed'), 0)
  INTO v_rider_refs_count
  FROM public.referrals
  WHERE referrer_id = p_user_id;

  SELECT true, discount_pct
  INTO v_has_ride_discount, v_ride_discount_pct
  FROM public.rider_discounts
  WHERE user_id = p_user_id AND is_used = false AND expires_at > now()
  ORDER BY created_at LIMIT 1;

  v_has_ride_discount := coalesce(v_has_ride_discount, false);
  v_ride_discount_pct := coalesce(v_ride_discount_pct, 0);
  v_remaining_for_discount := CASE
    WHEN (v_rider_refs_count % 5) = 0 AND v_rider_refs_count > 0 THEN 5
    ELSE 5 - (v_rider_refs_count % 5)
  END;

  -- ── 6. آخر 20 معاملة مالية ──
  SELECT jsonb_agg(
    jsonb_build_object(
      'id',          id,
      'type',        type,
      'amount',      amount,
      'description', description,
      'ride_id',     ride_id,
      'created_at',  to_char(created_at AT TIME ZONE 'Africa/Algiers', 'YYYY-MM-DD HH24:MI')
    ) ORDER BY created_at DESC
  )
  INTO v_transactions
  FROM (
    SELECT * FROM public.wallet_transactions
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 20
  ) t;

  -- ── النتيجة الكاملة ──
  RETURN jsonb_build_object(

    -- الملف الشخصي
    'profile', jsonb_build_object(
      'full_name',     v_full_name,
      'role',          v_role,
      'created_at',    v_created_at,
      'is_free_trial', v_is_free_trial,
      'is_sub_active', v_is_sub_active,
      'days_left',     GREATEST(0, v_days_left),
      'commission_rate', v_commission_rate
    ),

    -- المحفظة
    'wallet', jsonb_build_object(
      'balance',          v_balance,
      'referral_credit',  v_referral_credit,
      'has_pending_credit', v_has_pending_credit
    ),

    -- العمولات
    'commissions', jsonb_build_object(
      'total_paid_from_earnings',   v_total_commission_paid,
      'total_paid_from_credit',     v_total_commission_from_credit,
      'rides_covered_by_credit',    v_rides_covered_by_credit
    ),

    -- إحالات السائقات
    'driver_referrals', jsonb_build_object(
      'referral_code',    v_referral_code,
      'total_referred',   v_driver_refs_count,
      'total_earned',     v_driver_refs_earned
    ),

    -- إحالات الراكبات
    'rider_referrals', jsonb_build_object(
      'total_referred',         v_rider_refs_count,
      'has_ride_discount',      v_has_ride_discount,
      'ride_discount_pct',      v_ride_discount_pct,
      'remaining_for_discount', v_remaining_for_discount
    ),

    -- آخر المعاملات
    'transactions', coalesce(v_transactions, '[]'::jsonb)

  );
END;
$$;
