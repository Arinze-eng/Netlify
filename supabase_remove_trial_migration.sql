-- Admin feature: Remove trial from user (sets trial_ends_at to past so trial is immediately expired)
-- Project: ljnparociyyggmxdewwv

CREATE OR REPLACE FUNCTION public.admin_remove_trial(p_secret text, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);

  -- Set trial_ends_at to a time in the past so the trial is immediately expired
  UPDATE public.profiles
  SET trial_ends_at = now() - interval '1 day'
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_remove_trial(text,uuid) TO authenticated;
