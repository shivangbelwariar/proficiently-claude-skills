# Prerequisites by Skill

Check that required data files exist before proceeding. If any required file is missing, show the failure message and stop.

## Required Files

| File | setup | job-search | tailor-resume | cover-letter | network-scan | apply |
|------|:-----:|:----------:|:------------:|:------------:|:------------:|:-----:|
| `DATA_DIR/resume/*` | — | Required | Required | Required | Required | Required |
| `DATA_DIR/preferences.md` | — | Required | — | — | Required | — |
| `DATA_DIR/profile.md` | — | — | Recommended | Recommended | — | — |
| `DATA_DIR/linkedin-contacts.csv` | — | — | — | — | Required | — |
| `DATA_DIR/application-data.md` | — | — | — | — | — | Created if missing |

## Failure Messages

- **Resume missing**: Hard stop only. Log "resume missing" and skip to next job if in a loop.
- **Preferences missing**: Proceed with defaults. Do not stop.
- **LinkedIn contacts missing**: Skip network matching. Proceed without contacts.
- **Profile missing (tailor-resume)**: Proceed using resume text only. Do not warn or stop.
- **Profile missing (cover-letter)**: Proceed using resume text only. Do not warn or stop.
