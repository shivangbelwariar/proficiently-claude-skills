---
name: tailor-resume
description: Tailor your resume for a specific job posting
argument-hint: "job URL"
---

# Resume Tailoring Skill

Create compelling, tailored resumes that make it obvious you're the right candidate for a specific job.

## Quick Start

- `/proficiently:tailor-resume` - Start the flow (will ask for a job URL)
- `/proficiently:tailor-resume https://...` - Tailor resume for a specific job posting

## File Structure

```
scripts/
  tailor.md               # Resume tailoring subagent prompt
assets/
  templates/
    profile.md            # Template for work history profile
```

Shared data (all skills read/write here):
```
../../data/
  resume/                 # Source resume
  profile.md              # Work history from interview
  preferences.md          # Job preferences (for context)
  jobs/                   # Per-job application folders
    [company-slug]/
      posting.md          # Saved job description
      resume.md           # Tailored resume
      cover-letter.md     # Cover letter (from cover-letter skill)
```

---

## Workflow

### Step 0: Check Prerequisites

Check that the required data files exist:
- `../../data/resume/*` - at least one resume file (besides README.md)
- `../../data/profile.md` - populated with real content (not just a template)

If the resume is missing, tell the user: "Run `/proficiently:setup` first." Then stop.

If the profile is missing, warn the user clearly:

```
I don't have a work history profile yet. Without one, I'll be working
only from your resume text, which means I may get details wrong and
you'll need to correct multiple assumptions.

I strongly recommend running /proficiently:setup interview first.
This only needs to happen once, and it prevents errors on every future resume.
```

If the user chooses to proceed without a profile, set a flag to present all assumptions for verification (see Step 3a below).

If `$ARGUMENTS` is a URL, continue to Step 1.
Otherwise, ask for a job URL.

### Step 1: Get Job Details

Accept a job URL from the user (from `$ARGUMENTS` or by asking).

Use Claude in Chrome MCP tools to fetch the job posting:

```
1. tabs_context_mcp → get browser state
2. tabs_create_mcp → new tab
3. navigate → job URL
4. get_page_text → extract full job posting
```

Parse and extract:
- **Job title** and level (IC vs. manager, seniority)
- **Company** name and what they do
- **Responsibilities** - what the job actually involves day-to-day
- **Requirements** - must-have qualifications
- **Nice-to-haves** - preferred qualifications
- **Keywords** - industry terms, tools, methodologies mentioned
- **Team context** - who they report to, team size, cross-functional partners
- **Company stage/size** indicators

**Create a job folder** at `../../data/jobs/[company-slug]-[date]/` and save the parsed job posting to `posting.md`.

If the page can't be loaded or parsed, ask the user to paste the job description directly.

### Step 2: Analyze Match

Before writing, map the candidate's experience to the job:

1. **Level match**: Confirm the candidate's experience level matches the role. A VP-level candidate applying for a Director role should lean on strategic impact. A Director applying for VP should emphasize scope and leadership growth.

2. **Requirement mapping**: For each job requirement, identify the strongest evidence from the work history profile:
   - Direct experience ("Led SEO strategy" → job asks for SEO experience)
   - Analogous experience ("Scaled marketplace from 1M to 10M users" → job asks for growth experience)
   - Transferable skills ("Managed 30-person team" → job asks for leadership)

3. **Gap identification**: Note any requirements where the candidate has no clear match. These should NOT be fabricated - instead, find adjacent experience that demonstrates capability.

4. **Keyword alignment**: Identify the job posting's language and terminology to mirror in the resume.

5. **Compelling narrative**: Determine the 2-3 sentence story of why this person is the obvious choice. What's the throughline?

### Step 3: Generate Tailored Resume

Create the tailored resume following these principles:

**Structure:**
- **Header**: Name, contact info, LinkedIn (same as original)
- **Summary/Profile**: 2-3 sentences positioning the candidate specifically for THIS role. Not generic - reference the company and role context directly.
- **Experience**: All roles from the resume, but with bullet points rewritten, reordered, and selectively emphasized
- **Skills**: Reorganized to lead with what the job asks for
- **Education**: Same as original

**Bullet point principles:**
- Lead each role with the bullets most relevant to the target job
- Rewrite bullets to mirror the job posting's language where authentic
- Include metrics and quantified impact (from work history profile)
- Remove or de-emphasize bullets that aren't relevant to this specific role
- Add bullets from the work history profile that weren't on the original resume but ARE relevant to this job
- Each bullet should start with a strong action verb
- Each bullet should show: what you did → how you did it → what the impact was

**Level-matching:**
- For executive roles: emphasize strategy, P&L ownership, board interaction, team building, cross-functional leadership
- For director roles: emphasize program ownership, team management, operational excellence, stakeholder management
- For IC roles: emphasize hands-on execution, technical depth, individual contributions, collaboration

**Style rules:**
- Never use emdashes. Use commas, periods, colons, semicolons, or parentheses instead.
- Vary sentence structure. Not every bullet should follow the exact same pattern.
- Use natural, human language. Avoid phrases that sound like AI output.

**Strict accuracy rules (CRITICAL):**
- ONLY use information explicitly stated on the resume or in the work history profile
- NEVER assume business model (B2B vs B2C), revenue type, or company stage unless stated
- NEVER infer scope beyond what's written (e.g., don't add "P&L ownership" if resume says "revenue targets")
- NEVER add responsibilities, skills, or functional areas the candidate didn't mention
- NEVER assume cross-functional partnerships that aren't listed
- When the resume is ambiguous, use conservative language or omit the detail entirely
- If you need to frame experience differently for the target role, only reframe what IS there, never invent what ISN'T

**What NOT to do:**
- Don't fabricate experience or skills the candidate doesn't have
- Don't use generic buzzwords that aren't backed by specific experience
- Don't make the resume longer than 2 pages
- Don't change job titles or dates
- Don't remove roles (gaps look suspicious)
- Don't assume anything about the candidate's business, scope, or responsibilities that isn't explicitly documented

**Output:**

Save the tailored resume to `../../data/jobs/[company-slug]-[date]/resume.md`

Present the resume to the user with a brief explanation:

```
Here's your tailored resume for [Role] at [Company].

**Key changes I made:**
- [What was reordered/emphasized and why]
- [What bullets were rewritten and why]
- [What was added from your work history]

**The narrative:** [2-3 sentence pitch for why you're the right person]

The resume is saved to: data/jobs/[folder]/resume.md
```

### Step 3a: Verify Assumptions (if no profile exists)

If no work history profile was available, present the user with a list of every assumption made:

```
Before we finalize, here are the assumptions I made. Please correct
any that are wrong:

1. [Company] - I assumed [X]. Is that right?
2. [Role scope] - I described your scope as [Y]. Accurate?
3. [Business model] - I framed this as [Z]. Correct?
...
```

Wait for the user to verify or correct before finalizing. Apply all corrections to the resume AND save them to `../../data/profile.md` so they persist.

### Step 4: Iterate

Ask if the user wants to adjust anything:
- Tone (more technical, more strategic, more metrics-heavy)
- Emphasis (highlight certain roles or skills more)
- Length (condense to 1 page, expand detail in certain areas)
- Specific bullet points to rephrase

Apply changes and re-save.

### Step 5: Update Profile (ALWAYS)

**Every time the user corrects a factual detail**, update `../../data/profile.md` immediately:
- Business model corrections (e.g., "Proficiently is B2C, not B2B")
- Scope corrections (e.g., "I had revenue targets, not P&L ownership")
- Responsibility corrections (e.g., "I didn't manage candidate workflows")
- Any other clarification about roles, teams, or accomplishments

This prevents the same mistakes on future resumes. If the profile is still a blank template, create a new one with whatever the user has told you so far. Use the structure from `assets/templates/profile.md` but fill in only what you know for certain.

---

## Permissions Required

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/**)",
      "Write(~/.claude/skills/data/**)",
      "Edit(~/.claude/skills/data/**)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```
