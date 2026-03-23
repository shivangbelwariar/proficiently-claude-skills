---
name: job-search
description: Search for jobs matching my resume and preferences
argument-hint: "keyword to search"
---

# Job Search Skill

> **Priority hierarchy**: See `shared/references/priority-hierarchy.md` for conflict resolution.

Automated daily job search using browser automation.

## Quick Start

- `/proficiently:job-search` - Run daily search with default terms from matching rules
- `/proficiently:job-search AI infrastructure` - Search with specific keywords

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

### Step 2: Browser Search

Use Claude in Chrome MCP tools per `shared/references/browser-setup.md`.

**Determining the URL to navigate to:**
- **If `$ARGUMENTS` is empty or not provided:** Read `DATA_DIR/preferences.md`, find `## Default Search URLs > Hiring.cafe`, and navigate to that URL directly. All search filters are already encoded in it — do NOT re-enter any search terms or change any filters.
- **If `$ARGUMENTS` is provided:** Navigate to `https://hiring.cafe`, enter the search term, and apply filters (date posted, location) manually.

**Extracting results — IMPORTANT:** Do NOT use `get_page_text` on hiring.cafe. Extract using `javascript_tool` only, capturing both text AND the employer/apply URL from each card:

```javascript
// Extract job cards with text + apply link href
Array.from(document.querySelectorAll('[class*="job"], [class*="listing"], [class*="card"], tr, [role="listitem"]'))
  .slice(0, 50)
  .map(el => {
    const link = el.querySelector('a[href*="://"], a[href*="/jobs/"], a[href*="/apply"]');
    return { text: el.innerText.trim().slice(0, 300), href: link?.href || '' };
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
7. Repeat steps 2-6 until:
   - No new listings appear after scrolling (reached end), OR
   - 200+ total jobs collected (cap — stop here to avoid context overflow)

Deduplicate all collected listings by `(company, title)` before proceeding to Step 3.

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
- The candidate profile (from resume + preferences)
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
- **If `href` is empty or points to hiring.cafe**: navigate to the hiring.cafe listing and click through to get the employer URL

For each **High-fit** job with a resolved employer URL:
1. Navigate to the employer URL
2. Extract the job description via `javascript_tool`: `document.querySelector('[class*="description"], [class*="content"], article, main')?.innerText?.slice(0, 2000)`
3. Save to `DATA_DIR/jobs/[company-slug]-[date]/posting.md`

For **Medium-fit** jobs: use the captured `href` if available; skip navigation.

Never show hiring.cafe URLs to the user.

### Step 6: Auto-Apply to All High-Fit Jobs (3 in parallel)

**Do this automatically without asking the user. Do NOT present results first and wait — start applying immediately.**

Group all High-fit jobs (sorted by fit score) into batches of 3. For each batch:

1. **Open 3 tabs simultaneously** — call `tabs_create_mcp` three times, then navigate each tab to its employer URL
2. **Dispatch 3 apply subagents IN PARALLEL** — in a single Agent tool call with 3 independent sub-tasks, each receiving:
   - Tab ID (the pre-opened tab for this job)
   - Employer URL
   - Resume path: `/Users/gbelwariar/.proficiently/resume/Palak_SSE_Resume (1).pdf`
   - Full apply workflow per `skills/apply/SKILL.md` with argument `tab:<tabId>`
3. **Wait for all 3 to complete**, then log all 3 results to `DATA_DIR/job-history.md`
4. If a tab fails/crashes, log it as `apply-failed` and continue — do not block the other 2
5. Move to next batch of 3

After all High-fit jobs are applied to, loop back to Step 1 with different search keywords from `DATA_DIR/preferences.md`. Keep running continuously — never stop unless there are zero new results and all queues are empty.

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
