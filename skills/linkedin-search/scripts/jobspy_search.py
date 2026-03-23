#!/usr/bin/env python3
"""
LinkedIn job scraper using python-jobspy.
Scrapes PUBLIC LinkedIn listings — no login required.

Usage:
    python3 jobspy_search.py --search "java developer" --location "San Jose, CA"
    python3 jobspy_search.py --search "backend engineer" --location "San Jose, CA" --results 30 --hours 72 --remote
"""

import argparse
import json
import sys
import time

# Auto-install if missing
try:
    from jobspy import scrape_jobs
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "python-jobspy", "--break-system-packages", "-q"])
    from jobspy import scrape_jobs


def normalize_salary(job) -> str:
    """Convert JobSpy salary fields to a readable string."""
    try:
        min_s = job.get("min_amount")
        max_s = job.get("max_amount")
        currency = job.get("currency", "USD")
        interval = job.get("interval", "yearly")
        if min_s and max_s:
            if interval == "yearly":
                return f"${int(min_s/1000)}k-${int(max_s/1000)}k/yr"
            else:
                return f"${int(min_s)}-${int(max_s)}/{interval}"
        elif min_s:
            return f"${int(min_s/1000)}k+/yr"
    except Exception:
        pass
    return ""


def scrape_with_retry(search_term, location, results_wanted, hours_old, is_remote, max_retries=3):
    """Scrape LinkedIn with exponential backoff on rate limit errors."""
    delays = [5, 15, 45]
    for attempt in range(max_retries):
        try:
            jobs = scrape_jobs(
                site_name=["linkedin"],
                search_term=search_term,
                location=location,
                results_wanted=results_wanted,
                hours_old=hours_old,
                is_remote=is_remote,
                description_format="markdown",
                verbose=0,
            )
            return jobs
        except Exception as e:
            err = str(e).lower()
            if "429" in err or "rate" in err or "blocked" in err:
                if attempt < max_retries - 1:
                    wait = delays[attempt]
                    print(f"[linkedin-search] Rate limited, waiting {wait}s (attempt {attempt+1}/{max_retries})", file=sys.stderr)
                    time.sleep(wait)
                else:
                    print(f"[linkedin-search] Rate limited after {max_retries} retries. Returning partial results.", file=sys.stderr)
                    return None
            else:
                print(f"[linkedin-search] Error: {e}", file=sys.stderr)
                return None
    return None


def main():
    parser = argparse.ArgumentParser(description="Scrape LinkedIn jobs via JobSpy (no login required)")
    parser.add_argument("--search", required=True, help="Job search term")
    parser.add_argument("--location", default="San Jose, CA", help="Location string")
    parser.add_argument("--results", type=int, default=50, help="Max results (default 50, LinkedIn rate-limits at ~100)")
    parser.add_argument("--hours", type=int, default=72, help="Max age of postings in hours (default 72)")
    parser.add_argument("--remote", action="store_true", help="Remote jobs only")
    args = parser.parse_args()

    # Cap at 50 to stay within LinkedIn's rate limit comfort zone
    results_wanted = min(args.results, 50)

    jobs_df = scrape_with_retry(
        search_term=args.search,
        location=args.location,
        results_wanted=results_wanted,
        hours_old=args.hours,
        is_remote=args.remote,
    )

    if jobs_df is None or len(jobs_df) == 0:
        print("[]")
        return

    output = []
    for _, row in jobs_df.iterrows():
        # Truncate description to 500 chars to keep context window small
        desc = str(row.get("description") or "")
        if len(desc) > 500:
            desc = desc[:497] + "..."

        # Normalize location
        city = str(row.get("city") or "")
        state = str(row.get("state") or "")
        location_str = ", ".join(filter(None, [city, state])) or str(row.get("location") or args.location)

        # Date posted
        date_posted = ""
        dp = row.get("date_posted")
        if dp is not None:
            try:
                date_posted = str(dp.date()) if hasattr(dp, "date") else str(dp)
            except Exception:
                date_posted = str(dp)

        output.append({
            "title": str(row.get("title") or ""),
            "company": str(row.get("company") or ""),
            "location": location_str,
            "salary": normalize_salary(row),
            "link": str(row.get("job_url") or ""),
            "source": "linkedin",
            "date_posted": date_posted,
            "is_remote": bool(row.get("is_remote") or False),
            "job_type": str(row.get("job_type") or ""),
            "description": desc,
        })

    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
