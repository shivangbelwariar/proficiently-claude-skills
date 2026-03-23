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

**Do NOT open a browser for this step.** Use the Bash tool to call the JobSpy scraper.

**Determine search parameters:**
- **If `$ARGUMENTS` is empty or not provided:** Read `DATA_DIR/preferences.md`, find `## Default Search URLs > LinkedIn`, and use these defaults extracted from it:
  - `--search "software engineer"`
  - `--location "San Francisco Bay Area"`
  - `--hours 168` (7 days, matching `f_TPR=r604800`)
- **If `$ARGUMENTS` is provided:** Use `$ARGUMENTS` as the search term; keep default location and hours.

**Pagination — run 3 pages per search term to collect up to 150 results:**

```bash
SKILL_DIR="<directory containing this SKILL.md>"

# Page 1
python3 "$SKILL_DIR/scripts/jobspy_search.py" --search "<term>" --location "<location>" --results 50 --hours <hours> --offset 0

# Page 2
python3 "$SKILL_DIR/scripts/jobspy_search.py" --search "<term>" --location "<location>" --results 50 --hours <hours> --offset 50

# Page 3
python3 "$SKILL_DIR/scripts/jobspy_search.py" --search "<term>" --location "<location>" --results 50 --hours <hours> --offset 100
```

Stop paginating if a page returns 0 results (no more jobs available).

**Run searches for all target roles** from `preferences.md` (e.g., "software engineer", "java developer", "backend engineer"). Combine all results and deduplicate by `(company, title)` before proceeding.

**Parse the JSON output from each call.** Each job has:
- `title`, `company`, `location`, `salary`
- `link` — LinkedIn job URL (`linkedin.com/jobs/view/...`)
- `source` — always "linkedin"
- `date_posted`, `is_remote`, `job_type`
- `description` — first 500 chars

**If all pages return `[]` or errors:**
- Log "LinkedIn returned 0 results for [term]"
- Try next search term — do NOT fall back to hiring.cafe

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

### Step 6: Auto-Apply to All High-Fit Jobs (3 in parallel)

**Do this automatically without asking the user. Do NOT present results first and wait — start applying immediately.**

Group all High-fit jobs with resolved employer URLs into batches of 3. For each batch:

1. **Open 3 tabs simultaneously** — call `tabs_create_mcp` three times, navigate each to its employer URL
2. **Dispatch 3 apply subagents IN PARALLEL** — in a single Agent tool call with 3 independent sub-tasks, each receiving:
   - Tab ID (the pre-opened tab for this job)
   - Employer URL
   - Resume path: `/Users/gbelwariar/.proficiently/resume/Palak_SSE_Resume (1).pdf`
   - Full apply workflow per `skills/apply/SKILL.md` with argument `tab:<tabId>`
3. **Wait for all 3 to complete**, then log all 3 results to `DATA_DIR/job-history.md`
4. If a tab fails/crashes, log it as `apply-failed` and continue — do not block the other 2
5. Move to next batch of 3

After all High-fit jobs are processed, loop back to Step 1 with different search keywords from `preferences.md`. Keep running continuously — never stop unless there are zero new results and all queues are empty.

### Step 7: Summary (after all applications done)

Only after ALL high-fit jobs are applied to, show a brief summary. Do not wait for user response.

```markdown
## LinkedIn Session Summary for [DATE]

### Applied ([N] jobs)
| Title | Company | Location | Salary | Result |
|-------|---------|----------|--------|--------|
| ... | ... | ... | ... | Submitted / Skipped (Easy Apply only) |
```

For Easy Apply-only jobs that were skipped, show a brief note:
```
Skipped (Easy Apply only): X jobs — [Company1], [Company2]...
```

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
