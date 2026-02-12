---
name: setup
description: One-time onboarding - upload resume, set preferences, and do a work history interview
argument-hint: "'interview' to skip to the interview portion"
---

# Setup Skill

One-time onboarding that ensures all your data is in place before using the other skills.

## Quick Start

- `/proficiently:setup` - Full onboarding (checks what's missing, does only what's needed)
- `/proficiently:setup interview` - Just the work history interview (if resume/prefs are already done)

## File Structure

```
scripts/
  interview.md            # Deep-dive interview subagent prompt
```

Shared data (all skills read/write here):
```
../../data/
  resume/                 # Your resume PDF/DOCX
  preferences.md          # Job matching rules
  profile.md              # Work history from interview
```

---

## Workflow

### Step 0: Check What's Already Done

Check the state of these three data files and determine which phases to run:

1. **Resume**: Does `../../data/resume/` contain any files (besides README.md)?
2. **Preferences**: Does `../../data/preferences.md` exist and contain real content (not just a template or placeholder)?
3. **Profile**: Does `../../data/profile.md` exist and contain real content (not just a template)?

If `$ARGUMENTS` is "interview", skip directly to Step 3 (but still check that a resume exists first).

If everything is already set up, tell the user they're good to go and remind them of the available skills:
- `/proficiently:job-search` to find jobs
- `/proficiently:tailor-resume` to tailor a resume
- `/proficiently:cover-letter` to write a cover letter

Otherwise, run only the phases that are missing, in order.

### Step 1: Resume

If `../../data/resume/` is empty (or only contains README.md):

Ask the user to provide their resume. Accept either:
- A file path (copy it into `../../data/resume/`)
- Pasted text (save as `../../data/resume/resume.md`)

Confirm the resume was saved and briefly summarize what you see (name, most recent role, number of roles listed).

If the resume already exists, skip this step and say so.

### Step 2: Preferences

If `../../data/preferences.md` doesn't exist or contains only template/placeholder content:

Ask the user about their job search preferences:

1. **Target roles** - What job titles are you looking for? (e.g., VP Marketing, Director of Growth, Head of Product)
2. **Location** - Where are you willing to work? (Remote, specific cities, hybrid preferences)
3. **Salary** - What's your minimum total compensation? (base, bonus, equity expectations)
4. **Must-haves** - Any non-negotiable requirements? (company stage, industry, team size, etc.)
5. **Dealbreakers** - What should we always filter out? (agencies, crypto, travel requirements, specific industries, etc.)

Save to `../../data/preferences.md` in this format:

```markdown
# Job Preferences

## Target Roles
- [role 1]
- [role 2]

## Location
[location preferences]

## Compensation
- Minimum base: $[X]
- Target total comp: $[X]
- Notes: [equity preferences, etc.]

## Must-Haves
- [requirement 1]
- [requirement 2]

## Dealbreakers
- [dealbreaker 1]
- [dealbreaker 2]

## Nice-to-Haves
- [preference 1]
- [preference 2]
```

If preferences already exist, skip this step and say so.

### Step 3: Work History Interview

If `../../data/profile.md` doesn't exist or contains only template/placeholder content:

Conduct a thorough, conversational interview to build a comprehensive work history profile. Reference `scripts/interview.md` for the full interview framework.

**Interview approach:**

Work through each role on the resume, starting with the most recent. For each role:

1. **Context**: "Tell me about [Company]. What did they do, what stage were they at, what was the team like when you joined?"

2. **Your mandate**: "What were you hired to do? What was the state of things when you arrived?"

3. **What you built/changed**: "Walk me through the biggest things you accomplished. What did you actually do day-to-day vs. strategically?"

4. **Metrics and impact**: "Let's get specific about numbers. Revenue impact? Team size? Growth rates? User numbers? Anything you can quantify."

5. **How you did it**: "What was your approach? Any frameworks or methodologies? What tools or processes did you introduce?"

6. **Leadership**: "Who reported to you? How did you grow the team? Any cross-functional work?"

7. **Challenges**: "What was the hardest part? What didn't work? How did you adapt?"

8. **Why you left**: "What prompted the move? What were you looking for next?"

**Interview style:**
- Be conversational, not interrogative
- Ask follow-up questions when answers are vague ("Can you give me a specific example?")
- Push for metrics ("Do you remember roughly what the numbers were?")
- Note transferable patterns across roles
- Listen for themes (growth, leadership, turnarounds, scaling)
- If the candidate says "I don't remember exactly," ask for ranges or approximations

**After the interview:**

Save the comprehensive profile to `../../data/profile.md` using the structure from the tailor-resume template at `../tailor-resume/assets/templates/profile.md`. This profile should contain significantly MORE detail than would ever appear on a resume - it's the raw material for tailoring.

If the profile already exists, skip this step and say so.

### Step 4: Summary

After all phases are complete, give the user a brief summary of what's set up:

```
You're all set! Here's what we have:

- Resume: [filename] in data/resume/
- Preferences: [summary of target roles and key criteria]
- Work History Profile: [number of roles covered, completeness note]

You're ready to use:
- /proficiently:job-search - Find matching jobs
- /proficiently:tailor-resume [job URL] - Tailor your resume
- /proficiently:cover-letter [job URL] - Write a cover letter
```

---

## Permissions Required

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/**)",
      "Write(~/.claude/skills/data/**)",
      "Edit(~/.claude/skills/data/**)"
    ]
  }
}
```
