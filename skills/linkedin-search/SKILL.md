---
name: linkedin-search
description: Search LinkedIn for jobs matching my resume and preferences — no login required
argument-hint: "keyword to search (e.g. 'java developer')"
---

# LinkedIn Job Search Skill

> Scrapes public LinkedIn job listings via JobSpy — **no LinkedIn login, no ban risk**.
> The hiring.cafe skill (`/proficiently:job-search`) is a separate, independent option.

Search LinkedIn for jobs, filter and score them against your preferences, resolve employer career page URLs, and auto-apply to high-fit roles.

## Quick Start

- `/proficiently:linkedin-search` — search using target roles from preferences.md
- `/proficiently:linkedin-search java developer` — search with specific keywords
- `/proficiently:linkedin-search backend engineer remote` — remote jobs only

## Data Directory

Resolve the data directory using `shared/references/data-directory.md`.

---

## Workflow

### Step 0: Check Prerequisites

Resolve the data directory, then check prerequisites per `shared/references/prerequisites.md`. Resume and preferences are both required.

### Step 1: Load Context

Read:
- `DATA_DIR/resume/*` (candidate profile)
- `DATA_DIR/preferences.md` (search preferences, dealbreakers, must-haves)
- `DATA_DIR/job-history.md` (to skip already-seen companies and jobs)
- `DATA_DIR/linkedin-contacts.csv` (if it exists — for network matching)

Extract search terms:
1. From `$ARGUMENTS` if provided
2. From Target Roles in `preferences.md`

Extract location preference from `preferences.md` (default: "San Jose, CA").

### Step 2: LinkedIn Search via JobSpy

**Do NOT open a browser for this step.** Use the Bash tool to call the JobSpy scraper:

```bash
python3 "<SKILL_DIR>/scripts/jobspy_search.py" \
  --search "<search_term>" \
  --location "<location>" \
  --results 50 \
  --hours 72
```

Where `<SKILL_DIR>` is the directory containing this SKILL.md file.

For remote-only searches, add `--remote` flag.

**Parse the JSON output.** Each job has:
- `title`, `company`, `location`, `salary` — standard fields
- `link` — LinkedIn job URL (`linkedin.com/jobs/view/...`)
- `source` — always "linkedin"
- `date_posted`, `is_remote`, `job_type`
- `description` — first 500 chars of job description

**If the script returns `[]` or errors:**
- Log "LinkedIn returned 0 results for [term]"
- Try next search term from preferences
- Do NOT fall back to hiring.cafe — they are separate tools

**Run one search per target role from preferences** (e.g., "java developer", "backend engineer", "software engineer"). Combine and deduplicate results by `(company, title)` before proceeding.

### Step 3: Evaluate and Filter Jobs

**Pre-filter — auto-skip any job matching these hard dealbreakers:**
- Title contains: Staff, Lead, Manager, Principal, Director, VP, Head of, Senior Staff, Distinguished, Fellow
- Requires 8+ years experience
- Requires security clearance
- Requires relocation outside Bay Area (for non-remote roles)
- Already in `DATA_DIR/job-history.md` (skip duplicates)
- Company already applied to within the last 30 days

Score remaining jobs using `shared/references/fit-scoring.md` criteria (High/Medium/Low/Skip).

### Step 4: Save History

Append ALL jobs (regardless of score) to `DATA_DIR/job-history.md`:

```markdown
## [DATE] - LinkedIn Search: "[terms]"

| Job Title | Company | Location | Salary | Fit | Notes |
|-----------|---------|----------|--------|-----|-------|
| ... | ... | ... | ... | ... | ... |
```

### Step 5: Resolve Employer URLs (LinkedIn-Specific)

The LinkedIn URLs (`linkedin.com/jobs/view/...`) are NOT the employer careers page. For **High-fit** jobs, resolve the actual employer URL:

**Set up browser per `shared/references/browser-setup.md`** (`tabs_context_mcp` → `tabs_create_mcp`).

For each High-fit job:

1. Navigate to the LinkedIn job URL
2. **Look for "Apply on company website" or "Apply" button** that leads externally:
   - Use `javascript_tool` to extract: `document.querySelector('[data-tracking-control-name="public_jobs_apply-link-offsite_sign-up-modal"] a, a[href*="greenhouse"], a[href*="lever"], a[href*="workday"], a[href*="myworkdayjobs"], a[href*="ashbyhq"], [class*="apply"] a[href*="http"]')?.href`
   - Also try `read_page(filter="interactive")` and look for external apply links
3. **If "Apply on company website" is found:**
   - Extract the employer URL
   - Save the job description to `DATA_DIR/jobs/[company-slug]-[date]/posting.md`
   - Classify URL by ATS type per `shared/references/ats-patterns.md`
   - Add to appropriate queue (greenhouse/lever/workday/other)
4. **If only "Easy Apply" is shown (LinkedIn in-platform apply):**
   - **Skip this job entirely** — user cannot apply without logging in
   - Log it in job-history as "easy-apply-only, skipped"
   - Do NOT attempt to apply
5. **Fallback — regex the description** for employer apply links:
   - Look for patterns like `apply at careers.company.com`, greenhouse/lever/workday URLs in description text
   - If found, use that URL instead

For **Medium-fit** jobs: attempt to resolve employer URL but don't save full posting.

### Step 6: Present Results

Show only NEW High/Medium fits not already in history.

```markdown
## LinkedIn Results for [DATE]

### 1. [Title] at [Company]
- **Fit**: High
- **Salary**: $XXXk (if available)
- **Location**: Remote / San Jose, CA
- **Why**: [reason from fit-scoring]
- **Apply**: [employer careers page URL]
- **Network**: You know [First Last] ([Position]) at [Company]  ← if LinkedIn contacts loaded
```

For Easy Apply-only jobs that were skipped, show a brief note:
```
Skipped (Easy Apply only): X jobs — [Company1], [Company2]...
```

### Step 7.5: Auto-Apply to All High-Fit Jobs

**Do this automatically without asking the user.** For each High-fit job with a resolved employer URL:

1. Use the original resume from `DATA_DIR/resume/` as-is — never tailor
2. Run the apply workflow per `skills/apply/SKILL.md`
3. Log result to `DATA_DIR/job-history.md`
4. Move immediately to the next job

After all High-fit jobs are processed, loop back to Step 1 with different search keywords from `preferences.md`. Keep running continuously.

### Step 8: Learn from Feedback

If user provides feedback, update `DATA_DIR/preferences.md`:
- "No agencies" → add to dealbreakers
- "Prefer fintech" → add to nice-to-haves

---

## LinkedIn Easy Apply — What We Skip and Why

LinkedIn "Easy Apply" jobs require being logged in to apply via LinkedIn. Since this skill does **not** log in (no ban risk), Easy Apply-only jobs are skipped.

Jobs with "Apply on company website" have an external link to the employer's own careers page (Greenhouse, Lever, Workday, custom ATS). These are the ones we apply to.

Typically 30-60% of LinkedIn job listings have an external apply link.

---

## Permissions Required

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *jobspy_search.py*)",
      "Read(~/.proficiently/**)",
      "Write(~/.proficiently/**)",
      "Edit(~/.proficiently/**)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```
