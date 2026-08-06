-- ============================================================
-- DORA Referral System - قاعدة بيانات نظام الإحالة
-- ============================================================

-- 1. جدول الإحالات (referrals) - للسائقات والراكبات
CREATE TABLE IF NOT EXISTS public.referrals (
  id              uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_id     uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  referral_code   text        NOT NULL UNIQUE,
  referral_type   text        NOT NULL DEFAULT 'driver' CHECK (referral_type IN ('driver', 'rider')),
  status          text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
  reward_amount   numeric     NOT NULL DEFAULT 1000,
  reward_paid     boolean     NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  completed_at    timestamptz
);

-- 2. جدول خصومات الراكبات (rider_discounts) - مستقل تماماً
--    يُمنح خصم 20% على الرحلة القادمة بعد كل 5 ركاب مُحالين
CREATE TABLE IF NOT EXISTS public.rider_discounts (
  id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  discount_pct int         NOT NULL DEFAULT 20,
  is_used      boolean     NOT NULL DEFAULT false,
  ride_id      uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  used_at      timestamptz,
  expires_at   timestamptz NOT NULL DEFAULT (now() + interval '90 days')
);

-- 3. فهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id   ON public.referrals (referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referral_code ON public.referrals (referral_code);
CREATE INDEX IF NOT EXISTS idx_rider_discounts_user_id ON public.rider_discounts (user_id);

-- ============================================================
-- نظام إحالة السائقات: مكافأة 1000 دج عند كل تسجيل
-- ============================================================

-- 4. دالة: توليد كود إحالة فريد لكل مستخدم
CREATE OR REPLACE FUNCTION public.get_or_create_referral_code(p_user_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_code text;
BEGIN
  SELECT referral_code INTO v_code
  FROM public.referrals WHERE referrer_id = p_user_id AND referred_id IS NULL LIMIT 1;

  IF v_code IS NULL THEN
    v_code := upper(substring(replace(p_user_id::text, '-', ''), 1, 8));
    INSERT INTO public.referrals (referrer_id, referral_code)
    VALUES (p_user_id, v_code) ON CONFLICT (referral_code) DO NOTHING;
    IF NOT FOUND THEN
      v_code := upper(substring(replace(p_user_id::text, '-', ''), 1, 6))
                || to_char((random() * 99)::int, 'FM09');
      INSERT INTO public.referrals (referrer_id, referral_code) VALUES (p_user_id, v_code);
    END IF;
  END IF;
  RETURN v_code;
END;$$;

-- 5. دالة: تفعيل إحالة سائقة ومكافأة المُحيل بـ 1000 دج
CREATE OR REPLACE FUNCTION public.complete_referral(p_referral_code text, p_new_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_referral public.referrals%ROWTYPE;
  v_reward   numeric;
BEGIN
  SELECT * INTO v_referral FROM public.referrals
  WHERE referral_code = p_referral_code AND status = 'pending' AND referred_id IS NULL LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'كود الإحالة غير صالح أو مستخدم مسبقاً');
  END IF;
  IF v_referral.referrer_id = p_new_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'لا يمكنك استخدام كودك الخاص');
  END IF;

  v_reward := v_referral.reward_amount;
  UPDATE public.referrals
  SET referred_id = p_new_user_id, status = 'completed', reward_paid = true, completed_at = now()
  WHERE id = v_referral.id;

  UPDATE public.wallets SET balance = balance + v_reward, updated_at = now()
  WHERE user_id = v_referral.referrer_id;

  INSERT INTO public.wallet_transactions (user_id, amount, type, description)
  VALUES (v_referral.referrer_id, v_reward, 'topup', 'مكافأة إحالة DORA - تسجلت سائقة جديدة بكودك! 🎉');

  RETURN jsonb_build_object('success', true, 'reward', v_reward, 'referrer_id', v_referral.referrer_id);
END;$$;

-- ============================================================
-- نظام إحالة الركاب: 5 ركاب = خصم 20% على الرحلة القادمة
-- ============================================================

-- 6. دالة: تسجيل راكبة محالة وفحص الإنجاز كل 5 ركاب
CREATE OR REPLACE FUNCTION public.complete_rider_referral(p_referral_code text, p_new_rider_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_referral        public.referrals%ROWTYPE;
  v_completed_count int;
  v_new_code        text;
BEGIN
  SELECT * INTO v_referral FROM public.referrals
  WHERE referral_code = p_referral_code AND referral_type = 'rider'
    AND referred_id IS NULL AND status = 'pending' LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'كود غير صالح');
  END IF;
  IF v_referral.referrer_id = p_new_rider_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'لا يمكنك استخدام كودك الخاص');
  END IF;

  -- تسجيل هذه الإحالة
  UPDATE public.referrals
  SET referred_id = p_new_rider_id, status = 'completed', reward_paid = false, completed_at = now()
  WHERE id = v_referral.id;

  -- إضافة سطر إحالة جديد لنفس المُحيل (للاستمرار في الجمع)
  v_new_code := v_referral.referral_code || '_' || floor(random()*9999)::text;
  INSERT INTO public.referrals (referrer_id, referral_code, referral_type, reward_amount)
  VALUES (v_referral.referrer_id, v_new_code, 'rider', 0) ON CONFLICT DO NOTHING;

  -- إحصاء إجمالي الإحالات المكتملة
  SELECT count(*) INTO v_completed_count FROM public.referrals
  WHERE referrer_id = v_referral.referrer_id AND referral_type = 'rider' AND status = 'completed';

  -- كل 5 ركاب محالين → خصم 20% على الرحلة القادمة
  IF (v_completed_count % 5) = 0 THEN
    INSERT INTO public.rider_discounts (user_id, discount_pct)
    VALUES (v_referral.referrer_id, 20);

    RETURN jsonb_build_object(
      'success',         true,
      'milestone',       true,
      'completed_count', v_completed_count,
      'reward',          'خصم 20% على رحلتك القادمة! 🎉'
    );
  END IF;

  RETURN jsonb_build_object(
    'success',         true,
    'milestone',       false,
    'completed_count', v_completed_count,
    'remaining',       5 - (v_completed_count % 5)
  );
END;$$;

-- 7. دالة: تطبيق خصم 20% عند الدفع (يُستدعى عند إتمام الرحلة)
CREATE OR REPLACE FUNCTION public.apply_rider_discount(p_user_id uuid, p_ride_id uuid, p_fare numeric)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_discount        public.rider_discounts%ROWTYPE;
  v_discounted_fare numeric;
BEGIN
  SELECT * INTO v_discount FROM public.rider_discounts
  WHERE user_id = p_user_id AND is_used = false AND expires_at > now()
  ORDER BY created_at LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('has_discount', false, 'final_fare', p_fare);
  END IF;

  v_discounted_fare := p_fare * (1 - v_discount.discount_pct::numeric / 100);

  UPDATE public.rider_discounts
  SET is_used = true, ride_id = p_ride_id, used_at = now()
  WHERE id = v_discount.id;

  RETURN jsonb_build_object(
    'has_discount',  true,
    'discount_pct',  v_discount.discount_pct,
    'original_fare', p_fare,
    'final_fare',    round(v_discounted_fare, 2),
    'saved',         round(p_fare - v_discounted_fare, 2)
  );
END;$$;

-- 8. دالة: إحصائيات الإحالة الكاملة لأي مستخدم
CREATE OR REPLACE FUNCTION public.get_referral_stats(p_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_code                   text;
  v_driver_refs            int;
  v_rider_refs             int;
  v_total_earned           numeric;
  v_has_ride_discount      boolean;
  v_discount_pct           int;
  v_remaining_for_discount int;
BEGIN
  v_code        := public.get_or_create_referral_code(p_user_id);
  v_driver_refs := (SELECT count(*) FROM public.referrals
                    WHERE referrer_id = p_user_id AND referral_type = 'driver' AND status = 'completed');
  v_rider_refs  := (SELECT count(*) FROM public.referrals
                    WHERE referrer_id = p_user_id AND referral_type = 'rider'  AND status = 'completed');
  v_total_earned := (SELECT coalesce(sum(reward_amount), 0) FROM public.referrals
                     WHERE referrer_id = p_user_id AND status = 'completed' AND reward_paid = true);

  SELECT true, discount_pct INTO v_has_ride_discount, v_discount_pct
  FROM public.rider_discounts
  WHERE user_id = p_user_id AND is_used = false AND expires_at > now()
  ORDER BY created_at LIMIT 1;

  v_has_ride_discount      := coalesce(v_has_ride_discount, false);
  v_discount_pct           := coalesce(v_discount_pct, 0);
  v_remaining_for_discount := CASE WHEN (v_rider_refs % 5) = 0 AND v_rider_refs > 0 THEN 5
                                   ELSE 5 - (v_rider_refs % 5) END;

  RETURN jsonb_build_object(
    'referral_code',          v_code,
    'total_referrals',        v_driver_refs,
    'total_earned',           v_total_earned,
    'rider_referrals',        v_rider_refs,
    'has_ride_discount',      v_has_ride_discount,
    'ride_discount_pct',      v_discount_pct,
    'remaining_for_discount', v_remaining_for_discount
  );
END;$$;
