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

**Extracting results — IMPORTANT:** Do NOT use `get_page_text` on hiring.cafe. It will blow out the context window. Extract using `javascript_tool` only:

```javascript
// Extract visible job listing data from the page
Array.from(document.querySelectorAll('[class*="job"], [class*="listing"], [class*="card"], tr, [role="listitem"]'))
  .slice(0, 50)
  .map(el => el.innerText.trim())
  .filter(t => t.length > 20 && t.length < 500)
  .join('\n---\n')
```

If that selector doesn't match, take a screenshot to understand the page structure, then write a targeted JS selector. The goal is just listing rows (title, company, location, salary) — never the full page.

**Pagination — hiring.cafe uses infinite scroll:**
After extracting the initial visible results, collect more via auto-scroll:
1. Record the count of jobs collected so far
2. Scroll to bottom: `computer(action="scroll", coordinate=[760, 400], direction="down", amount=15)`
3. Wait 2 seconds for new results to load
4. Extract newly visible listings using the same `javascript_tool` selector
5. Add any new listings not already collected (deduplicate by title+company)
6. Repeat steps 2-5 until:
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

After pre-filtering, score remaining jobs against the candidate's resume and preferences using the criteria in `shared/references/fit-scoring.md`.

### Step 4: Save History

Append ALL jobs to `DATA_DIR/job-history.md`:

```markdown
## [DATE] - Search: "[terms]"

| Job Title | Company | Location | Salary | Fit | Notes |
|-----------|---------|----------|--------|-----|-------|
| ... | ... | ... | ... | ... | ... |
```

### Step 5: Resolve Employer URLs & Save Top Postings

For each **High-fit** job:
1. Click through the hiring.cafe listing to reach the actual employer careers page
2. Capture the direct employer URL for the job posting
3. Extract the job description using `javascript_tool` to pull the posting content (e.g. `document.querySelector('[class*="description"], [class*="content"], article, main')?.innerText`). Do NOT use `get_page_text` — employer pages often have huge footers, navs, and related listings that bloat the output and can blow out the context window.
4. Save to `DATA_DIR/jobs/[company-slug]-[date]/posting.md` with the employer URL at the top

For **Medium-fit** jobs, try to resolve the employer URL but don't save the full posting.

If you can't resolve the direct link for a job, note the company name so the user can find it themselves. Never show hiring.cafe URLs to the user.

### Step 6: Present Results

Show only NEW High/Medium fits not in previous history.

If LinkedIn contacts were loaded, cross-reference each result's company name against the "Company" column in the CSV. Use fuzzy matching (e.g. "Google" matches "Google LLC", "Alphabet/Google"). If there's a match, include the contact's name and title.

```markdown
## Top Matches for [DATE]

### 1. [Title] at [Company]
- **Fit**: High
- **Salary**: $XXXk
- **Location**: Remote
- **Why**: [reason]
- **Network**: You know [First Last] ([Position]) at [Company]
- **Apply**: [direct employer URL]
```

Omit the "Network" line if there are no contacts at that company.

### Step 7: Present Results

Show a brief summary of High/Medium fits found.

### Step 7.5: Auto-Apply to All High-Fit Jobs

**Do this automatically without asking the user.** For each High-fit job (in order of fit score):

1. Use the original resume from `DATA_DIR/resume/` as-is — do NOT tailor or modify it.
2. Run the apply workflow inline per `skills/apply/SKILL.md` — fill and auto-submit the application. Do not pause for approval or confirmation.
3. Log the result to `DATA_DIR/job-history.md`
4. Move immediately to the next High-fit job

After all High-fit jobs are applied to, loop back to Step 1 with different search keywords from `DATA_DIR/preferences.md`. Keep running continuously — never stop unless there are zero new results and all queues are empty.

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
