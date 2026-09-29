CREATE EXTENSION IF NOT EXISTS vector;

-- Shared updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =========================
-- profiles
-- =========================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  full_name TEXT,
  headline TEXT,
  summary TEXT,
  location TEXT,
  years_experience NUMERIC(4,1) CHECK (years_experience IS NULL OR (years_experience >= 0 AND years_experience <= 80)),
  desired_roles TEXT[] NOT NULL DEFAULT '{}',
  desired_locations TEXT[] NOT NULL DEFAULT '{}',
  remote_preference TEXT NOT NULL DEFAULT 'any' CHECK (remote_preference IN ('remote','hybrid','onsite','any')),
  min_salary INTEGER CHECK (min_salary IS NULL OR min_salary >= 0),
  salary_currency TEXT NOT NULL DEFAULT 'USD' CHECK (char_length(salary_currency) = 3),
  linkedin_url TEXT CHECK (linkedin_url IS NULL OR linkedin_url ~* '^https?://'),
  website_url TEXT CHECK (website_url IS NULL OR website_url ~* '^https?://'),
  open_to_work BOOLEAN NOT NULL DEFAULT true,
  embedding vector(1536),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_own_select" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "profiles_own_insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "profiles_own_update" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "profiles_own_delete" ON public.profiles FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- skills
-- =========================
CREATE TABLE public.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 100),
  normalized_name TEXT GENERATED ALWAYS AS (lower(trim(name))) STORED,
  category TEXT CHECK (category IS NULL OR category IN ('language','framework','tool','cloud','database','soft','domain','other')),
  proficiency TEXT CHECK (proficiency IS NULL OR proficiency IN ('beginner','intermediate','advanced','expert')),
  years_experience NUMERIC(4,1) CHECK (years_experience IS NULL OR (years_experience >= 0 AND years_experience <= 80)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT skills_unique_per_profile UNIQUE (profile_id, normalized_name)
);
CREATE INDEX idx_skills_user_id ON public.skills(user_id);
CREATE INDEX idx_skills_profile_id ON public.skills(profile_id);
CREATE INDEX idx_skills_normalized_name ON public.skills(normalized_name);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.skills TO authenticated;
GRANT ALL ON public.skills TO service_role;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "skills_own_select" ON public.skills FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "skills_own_insert" ON public.skills FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_own_update" ON public.skills FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_own_delete" ON public.skills FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_skills_updated_at BEFORE UPDATE ON public.skills FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- experiences
-- =========================
CREATE TABLE public.experiences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  company TEXT NOT NULL CHECK (char_length(trim(company)) BETWEEN 1 AND 200),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 1 AND 200),
  employment_type TEXT CHECK (employment_type IS NULL OR employment_type IN ('full_time','part_time','contract','internship','freelance','temporary')),
  location TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT false,
  description TEXT,
  highlights TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT experiences_date_order CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT experiences_current_has_no_end CHECK (NOT is_current OR end_date IS NULL)
);
CREATE INDEX idx_experiences_user_id ON public.experiences(user_id);
CREATE INDEX idx_experiences_profile_start ON public.experiences(profile_id, start_date DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.experiences TO authenticated;
GRANT ALL ON public.experiences TO service_role;
ALTER TABLE public.experiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "experiences_own_select" ON public.experiences FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "experiences_own_insert" ON public.experiences FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "experiences_own_update" ON public.experiences FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "experiences_own_delete" ON public.experiences FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_experiences_updated_at BEFORE UPDATE ON public.experiences FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- projects
-- =========================
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 200),
  description TEXT,
  url TEXT CHECK (url IS NULL OR url ~* '^https?://'),
  technologies TEXT[] NOT NULL DEFAULT '{}',
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT projects_date_order CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date)
);
CREATE INDEX idx_projects_user_id ON public.projects(user_id);
CREATE INDEX idx_projects_profile_id ON public.projects(profile_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO authenticated;
GRANT ALL ON public.projects TO service_role;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "projects_own_select" ON public.projects FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "projects_own_insert" ON public.projects FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_own_update" ON public.projects FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_own_delete" ON public.projects FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- jobs (shared catalog, ingested server-side only)
-- =========================
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL CHECK (source IN ('linkedin','company_careers','manual','other')),
  source_job_id TEXT NOT NULL CHECK (char_length(source_job_id) BETWEEN 1 AND 200),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 1 AND 300),
  company_name TEXT NOT NULL CHECK (char_length(trim(company_name)) BETWEEN 1 AND 200),
  company_linkedin_url TEXT CHECK (company_linkedin_url IS NULL OR company_linkedin_url ~* '^https?://'),
  location TEXT,
  remote_type TEXT CHECK (remote_type IS NULL OR remote_type IN ('remote','hybrid','onsite')),
  employment_type TEXT CHECK (employment_type IS NULL OR employment_type IN ('full_time','part_time','contract','internship','freelance','temporary')),
  seniority TEXT CHECK (seniority IS NULL OR seniority IN ('intern','entry','associate','mid','senior','lead','principal','director','executive')),
  description TEXT,
  apply_url TEXT CHECK (apply_url IS NULL OR apply_url ~* '^https?://'),
  url TEXT NOT NULL CHECK (url ~* '^https?://'),
  salary_min INTEGER CHECK (salary_min IS NULL OR salary_min >= 0),
  salary_max INTEGER CHECK (salary_max IS NULL OR salary_max >= 0),
  salary_currency TEXT CHECK (salary_currency IS NULL OR char_length(salary_currency) = 3),
  salary_period TEXT CHECK (salary_period IS NULL OR salary_period IN ('hour','day','month','year')),
  posted_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  content_hash TEXT,
  raw JSONB,
  embedding vector(1536),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT jobs_salary_range CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_max >= salary_min),
  CONSTRAINT jobs_source_unique UNIQUE (source, source_job_id)
);
CREATE INDEX idx_jobs_posted_at ON public.jobs(posted_at DESC NULLS LAST);
CREATE INDEX idx_jobs_company_name ON public.jobs(lower(company_name));
CREATE INDEX idx_jobs_remote_type ON public.jobs(remote_type);
CREATE INDEX idx_jobs_content_hash ON public.jobs(content_hash);
CREATE INDEX idx_jobs_title_trgm ON public.jobs USING gin (to_tsvector('english', title || ' ' || company_name || ' ' || coalesce(description, '')));
GRANT SELECT ON public.jobs TO authenticated;
GRANT ALL ON public.jobs TO service_role;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "jobs_read_authenticated" ON public.jobs FOR SELECT TO authenticated USING (true);
CREATE TRIGGER trg_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- job_skills
-- =========================
CREATE TABLE public.job_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 100),
  normalized_name TEXT GENERATED ALWAYS AS (lower(trim(name))) STORED,
  is_required BOOLEAN NOT NULL DEFAULT true,
  weight NUMERIC(3,2) NOT NULL DEFAULT 1.0 CHECK (weight >= 0 AND weight <= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT job_skills_unique UNIQUE (job_id, normalized_name)
);
CREATE INDEX idx_job_skills_job_id ON public.job_skills(job_id);
CREATE INDEX idx_job_skills_normalized_name ON public.job_skills(normalized_name);
GRANT SELECT ON public.job_skills TO authenticated;
GRANT ALL ON public.job_skills TO service_role;
ALTER TABLE public.job_skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_skills_read_authenticated" ON public.job_skills FOR SELECT TO authenticated USING (true);

-- =========================
-- saved_jobs
-- =========================
CREATE TABLE public.saved_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT saved_jobs_unique UNIQUE (user_id, job_id)
);
CREATE INDEX idx_saved_jobs_user_created ON public.saved_jobs(user_id, created_at DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_jobs TO authenticated;
GRANT ALL ON public.saved_jobs TO service_role;
ALTER TABLE public.saved_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "saved_jobs_own_select" ON public.saved_jobs FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "saved_jobs_own_insert" ON public.saved_jobs FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_jobs_own_update" ON public.saved_jobs FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_jobs_own_delete" ON public.saved_jobs FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_saved_jobs_updated_at BEFORE UPDATE ON public.saved_jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- applications
-- =========================
CREATE TABLE public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'saved' CHECK (status IN ('saved','applied','screening','interviewing','offer','rejected','withdrawn','accepted')),
  applied_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ,
  resume_url TEXT CHECK (resume_url IS NULL OR resume_url ~* '^https?://'),
  cover_letter TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT applications_unique UNIQUE (user_id, job_id)
);
CREATE INDEX idx_applications_user_status ON public.applications(user_id, status);
CREATE INDEX idx_applications_user_updated ON public.applications(user_id, updated_at DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.applications TO authenticated;
GRANT ALL ON public.applications TO service_role;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "applications_own_select" ON public.applications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "applications_own_insert" ON public.applications FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "applications_own_update" ON public.applications FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "applications_own_delete" ON public.applications FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_applications_updated_at BEFORE UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- job_matches
-- =========================
CREATE TABLE public.job_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  score NUMERIC(5,4) NOT NULL CHECK (score >= 0 AND score <= 1),
  skill_score NUMERIC(5,4) CHECK (skill_score IS NULL OR (skill_score >= 0 AND skill_score <= 1)),
  semantic_score NUMERIC(5,4) CHECK (semantic_score IS NULL OR (semantic_score >= 0 AND semantic_score <= 1)),
  matched_skills TEXT[] NOT NULL DEFAULT '{}',
  missing_skills TEXT[] NOT NULL DEFAULT '{}',
  reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
  algorithm_version TEXT NOT NULL DEFAULT 'v1',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT job_matches_unique UNIQUE (user_id, job_id, algorithm_version)
);
CREATE INDEX idx_job_matches_user_score ON public.job_matches(user_id, score DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.job_matches TO authenticated;
GRANT ALL ON public.job_matches TO service_role;
ALTER TABLE public.job_matches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_matches_own_select" ON public.job_matches FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "job_matches_own_insert" ON public.job_matches FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "job_matches_own_update" ON public.job_matches FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "job_matches_own_delete" ON public.job_matches FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_job_matches_updated_at BEFORE UPDATE ON public.job_matches FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================
-- target_companies
-- =========================
CREATE TABLE public.target_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 200),
  normalized_name TEXT GENERATED ALWAYS AS (lower(trim(name))) STORED,
  linkedin_url TEXT CHECK (linkedin_url IS NULL OR linkedin_url ~* '^https?://'),
  careers_url TEXT CHECK (careers_url IS NULL OR careers_url ~* '^https?://'),
  website_url TEXT CHECK (website_url IS NULL OR website_url ~* '^https?://'),
  priority SMALLINT NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
  notes TEXT,
  last_scanned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT target_companies_unique UNIQUE (user_id, normalized_name)
);
CREATE INDEX idx_target_companies_user_priority ON public.target_companies(user_id, priority);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.target_companies TO authenticated;
GRANT ALL ON public.target_companies TO service_role;
ALTER TABLE public.target_companies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "target_companies_own_select" ON public.target_companies FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "target_companies_own_insert" ON public.target_companies FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "target_companies_own_update" ON public.target_companies FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "target_companies_own_delete" ON public.target_companies FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER trg_target_companies_updated_at BEFORE UPDATE ON public.target_companies FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();