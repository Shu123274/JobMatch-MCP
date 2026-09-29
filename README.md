# Job Match Engine

Create JobMatch MCP, a production-ready Next.js + TypeScript + Tailwind/shadcn full-stack job-search system. Phase 1 only: create the database schema/migrations and secure server/API foundation first. Use Supabase PostgreSQL/Auth/pgvector-ready architecture, server-only secrets, RLS, Zod validation, typed domain models and services. Tables: profiles, skills, experiences, projects, jobs, job_skills, saved_jobs, applications, job_matches, target_companies. Include indexes, constraints, timestamps and least-privilege RLS. Define JobSource { searchJobs(input: JobSearchInput): Promise<Job[]> } abstraction but do not implement Apify yet. Prepare services for profile/jobs/applications/matching/sources and future MCP. Add README with architecture/setup/env/Supabase/Apify/MCP/ChatGPT/Vercel deployment guidance. Add tests for validation and service/query safety. No fake production jobs. Future phases must add Apify LinkedIn profile/jobs/company career pages, normalization/deduplication, deterministic + optional pgvector matching, MCP tools get_my_profile/search_jobs/get_job/match_jobs/search_company_jobs/save_job/track_application, and dashboard pages Profile/Search/Recommended/Saved/Applications/Target Companies. Never expose APIFY_API_TOKEN, SUPABASE_SERVICE_ROLE_KEY or OPENAI_API_KEY to browser. Never store LinkedIn passwords/cookies.

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/e153a0c0-d0c9-4d36-b6fd-99ae24129f0d).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
