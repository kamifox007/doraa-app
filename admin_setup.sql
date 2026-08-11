-- ══════════════════════════════════════════════════════════════════════
-- Admin Dashboard Backend Setup (Phase 3)
-- ══════════════════════════════════════════════════════════════════════

-- 1. إنشاء جدول Audit Logs لتسجيل عمليات الإدارة الحساسة
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    action TEXT NOT NULL,
    target_id UUID,
    before_state JSONB,
    after_state JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- فهرس لتسريع البحث في الـ Audit Logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_id ON public.audit_logs (admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);

-- 2. تحديث قيد types في wallet_transactions لإضافة adjustment و reversal
ALTER TABLE public.wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
ALTER TABLE public.wallet_transactions ADD CONSTRAINT wallet_transactions_type_check 
CHECK (type IN ('topup', 'commission', 'commission_from_credit', 'referral_bonus', 'promo', 'withdrawal', 'agent_transfer_out', 'agent_transfer_in', 'agent_commission', 'adjustment', 'reversal'));

-- 3. دالة تعديل الأرصدة للإدارة (Adjustment)
CREATE OR REPLACE FUNCTION public.admin_financial_adjustment(
    p_admin_id UUID,
    p_target_user_id UUID,
    p_amount NUMERIC,
    p_reason TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role TEXT;
    v_current_balance NUMERIC;
BEGIN
    -- التحقق من صلاحيات المشرف
    SELECT role INTO v_admin_role FROM public.user_profiles WHERE user_id = p_admin_id;
    IF v_admin_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Only admins can perform financial adjustments';
    END IF;

    -- جلب الرصيد الحالي
    SELECT balance INTO v_current_balance FROM public.wallets WHERE user_id = p_target_user_id;
    IF v_current_balance IS NULL THEN
        v_current_balance := 0;
    END IF;

    -- إذا كان المبلغ السالب أكبر من الرصيد
    IF p_amount < 0 AND ABS(p_amount) > v_current_balance THEN
        RAISE EXCEPTION 'Insufficient balance for this deduction';
    END IF;

    -- تطبيق التعديل
    INSERT INTO public.wallets (user_id, balance)
    VALUES (p_target_user_id, GREATEST(0, p_amount))
    ON CONFLICT (user_id)
    DO UPDATE SET balance = wallets.balance + p_amount, updated_at = now();

    -- تسجيل في الـ Ledger
    INSERT INTO public.wallet_transactions (user_id, type, amount, description)
    VALUES (p_target_user_id, 'adjustment', p_amount, 'Admin Adjustment: ' || p_reason);

    -- تسجيل في الـ Audit Logs
    INSERT INTO public.audit_logs (admin_id, action, target_id, before_state, after_state)
    VALUES (
        p_admin_id, 
        'financial_adjustment', 
        p_target_user_id, 
        jsonb_build_object('balance', v_current_balance), 
        jsonb_build_object('balance', v_current_balance + p_amount, 'amount_added', p_amount, 'reason', p_reason)
    );

    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Adjustment completed successfully',
        'new_balance', v_current_balance + p_amount
    );
END;
$$;

-- 4. دالة عكس عملية مالية (Reversal)
CREATE OR REPLACE FUNCTION public.admin_reverse_transaction(
    p_admin_id UUID,
    p_transaction_id UUID,
    p_reason TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_role TEXT;
    v_tx RECORD;
    v_current_balance NUMERIC;
BEGIN
    -- التحقق من صلاحيات المشرف
    SELECT role INTO v_admin_role FROM public.user_profiles WHERE user_id = p_admin_id;
    IF v_admin_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Only admins can perform reversals';
    END IF;

    -- جلب المعاملة الأصلية
    SELECT * INTO v_tx FROM public.wallet_transactions WHERE id = p_transaction_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction not found';
    END IF;

    -- لا يمكن عكس Reversal أو Adjustment معينة بدون دراسة، لكننا سنسمح بها حالياً مع تسجيلها.
    
    -- جلب الرصيد الحالي للمستخدم
    SELECT balance INTO v_current_balance FROM public.wallets WHERE user_id = v_tx.user_id;

    -- عكس القيمة
    -- إذا كانت المعاملة الأصلية موجبة (أخذ رصيد)، فالعكس سالب.
    -- وإذا كانت سالبة (خصم رصيد)، فالعكس موجب.
    INSERT INTO public.wallets (user_id, balance)
    VALUES (v_tx.user_id, -v_tx.amount)
    ON CONFLICT (user_id)
    DO UPDATE SET balance = wallets.balance - v_tx.amount, updated_at = now();

    -- تسجيل الـ Reversal في الـ Ledger
    INSERT INTO public.wallet_transactions (user_id, type, amount, description)
    VALUES (v_tx.user_id, 'reversal', -v_tx.amount, 'Reversal of TX ' || p_transaction_id || '. Reason: ' || p_reason);

    -- تسجيل في الـ Audit Logs
    INSERT INTO public.audit_logs (admin_id, action, target_id, before_state, after_state)
    VALUES (
        p_admin_id, 
        'transaction_reversal', 
        v_tx.user_id, 
        jsonb_build_object('original_tx_id', p_transaction_id, 'original_amount', v_tx.amount), 
        jsonb_build_object('reversed_amount', -v_tx.amount, 'reason', p_reason)
    );

    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Transaction reversed successfully'
    );
END;
$$;
