---
name: job-search
description: Search for jobs matching my resume and preferences
argument-hint: "keyword to search OR a full hiring.cafe URL"
---

# Job Search Skill

> **Priority hierarchy**: See `shared/references/priority-hierarchy.md` for conflict resolution.

Automated daily job search using browser automation.

## Quick Start

- `/proficiently:job-search` - Run daily search with default URL from preferences.md
- `/proficiently:job-search AI infrastructure` - Search with specific keywords
- `/proficiently:job-search https://hiring.cafe/...` - Use a specific URL directly (overrides default for this session)

## File Structure

```
scripts/
  evaluate-jobs.md     # Subagent for parallel job evaluation
assets/
  templates/           # Format templates (committed)
```

## Data Directory

Resolve the data directory using `shared/references/data-directory.md`.

---

## Workflow

### Step 0: Check Prerequisites

Resolve the data directory, then check prerequisites per `shared/references/prerequisites.md`. Resume and preferences are both required.

### Step 1: Load Context

Read these files:
- `DATA_DIR/resume/*` (candidate profile)
- `DATA_DIR/preferences.md` (preferences)
- `DATA_DIR/job-history.md` (to avoid duplicates)
- `DATA_DIR/linkedin-contacts.csv` (if it exists — for network matching)

Extract search terms from:
1. `$ARGUMENTS` if provided
2. Target roles from preferences

**Build seen-jobs index** (for O(1) dedup in Step 3):
Parse job-history.md once and extract all previously seen jobs as a compact string:
`seen_jobs = "company::title\ncompany::title\n..."` (all lowercase)
Use `seen_jobs.includes(company.toLowerCase()+'::'+title.toLowerCase())` for duplicate checks — do NOT re-read the file per job.

**Extract candidate profile summary** (to pass inline to scorer — no file re-reads needed):
```
Profile: [target titles] | [YOE] yrs | [location] | [salary range] | [tech stack top 8] | Dealbreakers: [list]
```

### Step 2: Browser Search

Use Claude in Chrome MCP tools per `shared/references/browser-setup.md`.

**Determining the URL to navigate to:**
- **If `$ARGUMENTS` is empty or not provided:** Read `DATA_DIR/preferences.md`, find `## Default Search URLs > Hiring.cafe`, and navigate to that URL directly. All search filters are already encoded in it — do NOT re-enter any search terms or change any filters.
- **If `$ARGUMENTS` starts with `http`:** Navigate directly to that URL as-is. Treat it exactly like the default URL — all filters are encoded in it, do NOT re-enter anything.
- **If `$ARGUMENTS` is keywords (not a URL):** Navigate to `https://hiring.cafe`, enter the search term, and apply filters (date posted, location) manually.

**Extracting results — IMPORTANT:** Do NOT use `get_page_text` on hiring.cafe. Extract using `javascript_tool` only, capturing both text AND the employer/apply URL from each card:

```javascript
// Extract job cards with text + apply link href (including data-* attribute fallbacks)
Array.from(document.querySelectorAll('[class*="job"], [class*="listing"], [class*="card"], tr, [role="listitem"]'))
  .slice(0, 50)
  .map(el => {
    const link = el.querySelector('a[href*="://"], a[href*="/jobs/"], a[href*="/apply"]');
    const btn = el.querySelector('[data-href], [data-url], [data-apply-url]');
    const href = link?.href || btn?.dataset?.href || btn?.dataset?.url || btn?.dataset?.applyUrl || '';
    return { text: el.innerText.trim().slice(0, 300), href };
  })
  .filter(j => j.text.length > 20)
```

If that selector doesn't match, take a screenshot to understand the page structure, then write a targeted JS selector.

**Pagination — hiring.cafe uses infinite scroll:**
After extracting the initial visible results, collect more via auto-scroll:
1. Record the count of jobs collected so far
2. Scroll to bottom: `computer(action="scroll", coordinate=[760, 400], direction="down", amount=15)`
3. Wait **1 second** for new results to load
4. Extract newly visible listings using the same `javascript_tool` selector
5. **Immediately drop** any job whose title contains: Staff, Lead, Manager, Principal, Director, VP, Head of, Senior Staff, Distinguished, Fellow — don't accumulate dealbreakers
6. Add remaining new listings not already collected (deduplicate by title+company)
7. Repeat steps 2-6 until no new listings appear after scrolling (reached end of page)

Deduplicate all collected listings by `(company, title)` using `seen_jobs` index from Step 1 before proceeding to Step 3. **No hard cap** — collect all available listings.

**Note:** Never show hiring.cafe links to the user — resolve direct employer URLs in Step 5.

### Step 3: Evaluate and Filter Jobs

**Pre-filter — auto-skip any job that matches these hard dealbreakers BEFORE scoring:**
- Title contains: Staff, Lead, Manager, Principal, Director, VP, Head of, Senior Staff, Distinguished, Fellow
- Requires 8+ years experience (any mention of "8+ years", "10+ years", etc.)
- Requires security clearance
- Requires relocation outside Bay Area (for non-remote roles)
- Already in `DATA_DIR/job-history.md` (previously seen — skip duplicates)
- Company already applied to within the last 30 days (check job-history.md)

After pre-filtering, score remaining jobs using the `scripts/evaluate-jobs.md` subagent. Pass it:
- **The candidate profile summary extracted at Step 1** (inline — do NOT tell subagent to re-read files)
- The full batch of pre-filtered job listings
- The fit-scoring criteria from `shared/references/fit-scoring.md`

The subagent returns a scored JSON array. Use that to split jobs into High/Medium/Low/Skip.

### Step 4: Save History

Append ALL jobs to `DATA_DIR/job-history.md`:

```markdown
## [DATE] - Search: "[terms]"

| Job Title | Company | Location | Salary | Fit | Notes |
|-----------|---------|----------|--------|-----|-------|
| ... | ... | ... | ... | ... | ... |
```

### Step 5: Resolve Employer URLs & Save Top Postings

**Fast path — use URL already captured in Step 2:**
For each High-fit job, check if `href` was captured during extraction:
- **If `href` is an employer/ATS URL** (contains `greenhouse.io`, `lever.co`, `workday`, `ashbyhq`, `workable`, `smartrecruiters`, or any non-hiring.cafe domain): use it directly — no navigation needed
- **If `href` is empty or points to hiring.cafe**: resolve via new-tab capture:
  1. Navigate to the hiring.cafe job listing URL
  2. Use `find("Apply now")` or `find("Apply")` to locate the apply button coordinates
  3. Click it with `computer(action="left_click")` at those coordinates
  4. Wait 2 seconds for the new tab to open
  5. Call `tabs_context_mcp` — find the newly opened tab (it will have the employer ATS URL)
  6. Capture that tab's URL as the employer URL
  7. Close or reuse that tab — do not leave stray tabs open
  8. Use the captured URL for the rest of the flow

For each **High-fit** job with a resolved employer URL:
1. Navigate to the employer URL
2. Extract the job description via `javascript_tool`: `document.querySelector('[class*="description"], [class*="content"], article, main')?.innerText?.slice(0, 2000)`
3. Save to `DATA_DIR/jobs/[company-slug]-[date]/posting.md`

For **Medium-fit** jobs: use the captured `href` if available; skip navigation.

Never show hiring.cafe URLs to the user.

### Step 6: Continuous Parallel Pipeline (Fetch + Apply Simultaneously)

**Do this automatically without asking the user. Do NOT present results first.**

The pipeline has two parts running simultaneously:
- **Fetcher** — background agent continuously finding and scoring new jobs, writing to a shared queue file
- **Apply pool** — 5 tabs always working, reading from the queue

---

**Queue file: `DATA_DIR/apply-queue.md`**
```
| Status  | Title | Company | URL | Score | Added |
| pending | ...   | ...     | ... | High  | date  |
| claimed | ...   | ...     | ... | High  | date  |
| done    | ...   | ...     | ... | High  | date  |
```
- `pending` = ready to apply
- `claimed` = an apply agent is working on it
- `done` = applied, skipped, or failed

---

**Launch Fetcher as background agent** (`run_in_background: true`):

> Task: Continuously search hiring.cafe for new High-fit jobs and append them to `DATA_DIR/apply-queue.md`.
> 1. Cycle through all search terms in `DATA_DIR/preferences.md`
> 2. For each term: navigate to hiring.cafe, scroll to collect all listings, pre-filter (dealbreakers), score using `scripts/evaluate-jobs.md`
> 3. For High-fit jobs: resolve employer URL (Step 5 logic), append to `apply-queue.md` with status `pending` — skip any already in `job-history.md` or `apply-queue.md`
> 4. After all search terms exhausted: loop back to the first term with fresh results
> 5. Append `| DONE | | | | | |` row only when no new results across ALL search terms for 2 full cycles

---

**Apply pool — start after queue has ≥5 pending rows:**
1. Open 5 tabs, navigate each to first 5 `pending` employer URLs, mark them `claimed` in queue
2. Dispatch apply agent for each tab (`run_in_background: true`): Tab ID, Employer URL, Resume `~/.proficiently/resume/<your-resume.pdf> (read exact path from DATA_DIR/application-data.md → File Paths → Resume PDF)`, workflow per `skills/apply/SKILL.md` with `tab:<tabId>`

**Sliding window loop:**
- When any agent completes:
  1. Log result to `DATA_DIR/job-history.md`, mark row `done` in `apply-queue.md`
  2. Read `apply-queue.md` for next `pending` row
     - **If found**: mark `claimed`, navigate same tab to its URL, dispatch next apply agent
     - **If empty but no DONE marker**: wait 15s, check again — do NOT stop
     - **If DONE marker AND no pending rows AND all slots idle**: stop
- Tab crashes: mark `apply-failed`, free slot, pull next pending

The 5 tabs opened at initialization are reused — tab count never exceeds 5. Fetcher and apply pool run simultaneously with zero idle time.

### Step 7: Summary (after all applications done)

Only after ALL high-fit jobs are applied to, show a brief summary of what was done. Do not wait for user response.

Show only NEW High/Medium fits processed in this session.

If LinkedIn contacts were loaded, cross-reference each result's company name against the "Company" column in the CSV. Use fuzzy matching (e.g. "Google" matches "Google LLC", "Alphabet/Google"). If there's a match, include the contact's name and title.

```markdown
## Session Summary for [DATE]

### Applied ([N] jobs)
| Title | Company | Location | Salary | Result |
|-------|---------|----------|--------|--------|
| ... | ... | ... | ... | Submitted / Skipped |
```

### Step 8: Learn from Feedback

If user provides feedback at any point, update `DATA_DIR/preferences.md`:
- "No agencies" → add to dealbreakers
- "Prefer AI companies" → add to nice-to-haves
- "Minimum $350k" → update salary threshold

---

## Response Format

Structure user-facing output with these sections:

1. **Top Matches** — table or list of High/Medium fits with company, role, fit rating, salary, location, network contacts, and direct URL
2. **Next Steps** — suggest `/proficiently:tailor-resume` and `/proficiently:cover-letter` for top matches

---

## Permissions Required

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/**)",
      "Read(~/.proficiently/**)",
      "Write(~/.proficiently/**)",
      "Edit(~/.proficiently/**)",
      "Bash(crontab *)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```
