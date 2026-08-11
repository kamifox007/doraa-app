-- ══════════════════════════════════════════════════════════════════════
-- Agent Float Integration SQL
-- هذا الملف يقوم بتعديل النظام المالي الحالي ليسمح للوكلاء (Agents) باستخدام المحافظ
-- وإجراء عمليات شحن للعملاء دون كسر النظام المالي القديم.
-- ══════════════════════════════════════════════════════════════════════

-- 1. تحديث جدول user_profiles لإضافة دور 'agent'
-- نقوم بإزالة القيد القديم وإنشاء قيد جديد يضم دور agent
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
CHECK (role IN ('rider', 'driver', 'pending_driver', 'admin', 'agent'));

-- 2. تحديث جدول wallet_transactions لإضافة أنواع العمليات الخاصة بالوكيل
ALTER TABLE public.wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
ALTER TABLE public.wallet_transactions ADD CONSTRAINT wallet_transactions_type_check 
CHECK (type IN ('topup', 'commission', 'commission_from_credit', 'referral_bonus', 'promo', 'withdrawal', 'agent_transfer_out', 'agent_transfer_in', 'agent_commission'));

-- 3. إنشاء دالة لشحن رصيد الوكيل من قبل الإدارة
CREATE OR REPLACE FUNCTION public.admin_topup_agent(
    p_admin_id uuid,
    p_agent_id uuid,
    p_amount numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role text;
    v_agent_role text;
BEGIN
    -- التحقق من أن المبلغ موجب
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;

    -- التحقق من صلاحيات المشرف
    SELECT role INTO v_admin_role FROM public.user_profiles WHERE user_id = p_admin_id;
    IF v_admin_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Only admins can top-up agent floats';
    END IF;

    -- التحقق من أن المستلم هو وكيل
    SELECT role INTO v_agent_role FROM public.user_profiles WHERE user_id = p_agent_id;
    IF v_agent_role != 'agent' THEN
        RAISE EXCEPTION 'Invalid target: Target user is not an agent';
    END IF;

    -- إضافة الرصيد للوكيل (أو إنشاء المحفظة إن لم تكن موجودة)
    INSERT INTO public.wallets (user_id, balance)
    VALUES (p_agent_id, p_amount)
    ON CONFLICT (user_id)
    DO UPDATE SET balance = wallets.balance + p_amount,
                  updated_at = now();

    -- تسجيل العملية في الـ Ledger
    INSERT INTO public.wallet_transactions (user_id, type, amount, description)
    VALUES (p_agent_id, 'topup', p_amount, 'Admin top-up to Agent Float');

    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Agent float topped up successfully',
        'amount', p_amount
    );
END;
$$;

-- 4. إنشاء دالة ليقوم الوكيل بشحن رصيد عميل
-- العملية هنا Atomic، إما أن تنجح بالكامل (خصم وإيداع) أو تفشل بالكامل.
CREATE OR REPLACE FUNCTION public.agent_recharge_customer(
    p_agent_id uuid,
    p_customer_id uuid,
    p_amount numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_agent_role text;
    v_agent_balance numeric;
BEGIN
    -- التحقق من أن المبلغ موجب
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;

    -- التحقق من أن المستخدم المرسل هو وكيل
    SELECT role INTO v_agent_role FROM public.user_profiles WHERE user_id = p_agent_id;
    IF v_agent_role != 'agent' THEN
        RAISE EXCEPTION 'Unauthorized: Only agents can recharge customers this way';
    END IF;

    -- جلب رصيد الوكيل والتحقق من كفايته
    SELECT balance INTO v_agent_balance FROM public.wallets WHERE user_id = p_agent_id;
    IF v_agent_balance IS NULL OR v_agent_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient agent float balance';
    END IF;

    -- 1. خصم الرصيد من الوكيل
    UPDATE public.wallets 
    SET balance = balance - p_amount, 
        updated_at = now()
    WHERE user_id = p_agent_id;

    -- 2. تسجيل عملية الخصم من الوكيل في الـ Ledger
    INSERT INTO public.wallet_transactions (user_id, type, amount, description)
    VALUES (p_agent_id, 'agent_transfer_out', -p_amount, 'Agent recharge to customer: ' || p_customer_id);

    -- 3. إضافة الرصيد للعميل (وإنشاء المحفظة إن لم تكن موجودة)
    INSERT INTO public.wallets (user_id, balance)
    VALUES (p_customer_id, p_amount)
    ON CONFLICT (user_id)
    DO UPDATE SET balance = wallets.balance + p_amount,
                  updated_at = now();

    -- 4. تسجيل عملية الإيداع للعميل في الـ Ledger
    INSERT INTO public.wallet_transactions (user_id, type, amount, description)
    VALUES (p_customer_id, 'agent_transfer_in', p_amount, 'Recharged by Agent: ' || p_agent_id);

    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Customer recharged successfully by agent',
        'amount', p_amount
    );
END;
$$;
