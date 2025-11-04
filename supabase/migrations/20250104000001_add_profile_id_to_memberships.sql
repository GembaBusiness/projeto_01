-- Migration: Add profile_id to memberships table
-- Purpose: Enable direct access to profiles from memberships without going through auth.users
-- Date: 2025-01-04

-- ============================================================================
-- STEP 1: Add profile_id column to memberships
-- ============================================================================

ALTER TABLE public.memberships
ADD COLUMN profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

COMMENT ON COLUMN public.memberships.profile_id IS
  'Direct reference to profiles table. Denormalized from user_id for simplified queries without SECURITY DEFINER functions.';

-- ============================================================================
-- STEP 2: Create index for performance
-- ============================================================================

CREATE INDEX idx_memberships_profile_id ON public.memberships(profile_id);

COMMENT ON INDEX idx_memberships_profile_id IS
  'Index to optimize JOINs between memberships and profiles tables.';

-- ============================================================================
-- STEP 3: Populate profile_id for existing records
-- ============================================================================

-- Since profiles.id = auth.users.id, we can directly copy user_id to profile_id
UPDATE public.memberships
SET profile_id = user_id
WHERE profile_id IS NULL;

-- ============================================================================
-- STEP 4: Make profile_id NOT NULL after population
-- ============================================================================

ALTER TABLE public.memberships
ALTER COLUMN profile_id SET NOT NULL;

-- ============================================================================
-- STEP 5: Create trigger function to sync profile_id with user_id
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sync_membership_profile_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- On INSERT or UPDATE, ensure profile_id matches user_id
  -- This maintains consistency since profiles.id = auth.users.id
  NEW.profile_id := NEW.user_id;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sync_membership_profile_id() IS
  'Trigger function to automatically sync profile_id with user_id on INSERT/UPDATE operations.';

-- ============================================================================
-- STEP 6: Create trigger
-- ============================================================================

CREATE TRIGGER trg_sync_membership_profile_id
  BEFORE INSERT OR UPDATE OF user_id ON public.memberships
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_membership_profile_id();

COMMENT ON TRIGGER trg_sync_membership_profile_id ON public.memberships IS
  'Ensures profile_id is always synchronized with user_id.';

-- ============================================================================
-- STEP 7: Add constraint to ensure profile_id and user_id are always in sync
-- ============================================================================

-- This check constraint ensures data integrity at the database level
ALTER TABLE public.memberships
ADD CONSTRAINT chk_memberships_profile_user_sync
CHECK (profile_id = user_id);

COMMENT ON CONSTRAINT chk_memberships_profile_user_sync ON public.memberships IS
  'Ensures profile_id is always equal to user_id, maintaining referential integrity.';

-- ============================================================================
-- VERIFICATION QUERIES (commented out - use for testing)
-- ============================================================================

-- Verify all records have profile_id set
-- SELECT COUNT(*) as total_memberships,
--        COUNT(profile_id) as with_profile_id,
--        COUNT(*) - COUNT(profile_id) as missing_profile_id
-- FROM public.memberships;

-- Test query without SECURITY DEFINER
-- SELECT
--   m.id,
--   m.company_id,
--   m.status,
--   p.full_name,
--   p.avatar_url,
--   p.job_title
-- FROM public.memberships m
-- JOIN public.profiles p ON m.profile_id = p.id
-- WHERE m.company_id = 'your-company-id';
