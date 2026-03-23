# Browser Automation Setup

Standard sequence for skills that use Claude in Chrome MCP tools to fetch web pages.

## Tab Setup

```
1. tabs_context_mcp → get browser state
2. tabs_create_mcp → create a new tab
3. navigate → target URL
4. get_page_text → extract page content
```

## Context Window Safety

**Avoid `get_page_text` on large or dynamic pages** (job boards, search results, listing pages, dashboards). It returns the entire page and can blow out the context window, making the conversation unrecoverable.

Instead, use targeted extraction:
- `javascript_tool` with a selector to extract only the content you need
- `read_page` to get structured element refs
- `get_page_text` is safe only for simple pages with a single article/posting

## Error Handling

- If `tabs_context_mcp` returns no tabs or an error, retry once after 3 seconds. If it still fails, skip this job and move to the next one in the queue. Never ask the user.
- If `navigate` fails or the page doesn't load, retry once. If it still fails, log the URL as "failed to load" and skip to the next job.
- If `get_page_text` returns empty or unusable content, try `read_page` as a fallback. If that also fails, skip this job and continue.
- Do not stop the workflow for browser errors. Always move to the next job.
