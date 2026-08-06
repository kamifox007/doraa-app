-- ══════════════════════════════════════════════════════════════
-- دالة تعويض السائقة عن الخصم (Promo Compensation)
-- هذه الدالة تضيف قيمة الخصم الممنوح للراكبة إلى محفظة السائقة
-- لكي لا تخسر السائقة أي شيء من أرباحها.
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION apply_promo_compensation(
  p_driver_id UUID,
  p_ride_id UUID,
  p_discount_amount NUMERIC
)
RETURNS void AS $$
BEGIN
  -- لا نفعل شيئاً إذا كان الخصم 0
  IF p_discount_amount <= 0 THEN
    RETURN;
  END IF;

  -- 1. إضافة التعويض لمحفظة السائقة
  UPDATE user_profiles
    SET wallet_balance = wallet_balance + p_discount_amount
  WHERE user_id = p_driver_id;

  -- 2. تسجيل المعاملة في السجل كإضافة (Topup/Compensation)
  INSERT INTO wallet_transactions (user_id, type, amount, description, ride_id)
  VALUES (p_driver_id, 'topup', p_discount_amount, 'تعويض DORA لخصم الراكبة (Promo)', p_ride_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
