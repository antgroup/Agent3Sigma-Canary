## Description: <br>
Default web search for OpenClaw that searches multiple web engines through Prismfy, with quota checks and engine, time, domain, page, language, and raw JSON options. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[uroboros1205](https://clawhub.ai/user/uroboros1205) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
OpenClaw users and agent developers use this skill to run live web searches, check Prismfy quota, and retrieve source-backed results for current information, code examples, community discussions, news, and academic papers. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Search requests and quota checks are sent to Prismfy using a bearer API key. <br>
Mitigation: Use a dedicated, rotatable PRISMFY_API_KEY and avoid placing secrets, personal data, or confidential project details in search queries. <br>
Risk: The install hook makes Prismfy the default web search path for OpenClaw. <br>
Mitigation: Install only when that default search behavior is desired, and disable or remove the hook if manual-only searches are preferred. <br>


## Reference(s): <br>
- [Prismfy homepage](https://prismfy.io) <br>
- [ClawHub skill page](https://clawhub.ai/uroboros1205/prismfy-search) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, guidance] <br>
**Output Format:** [Markdown search results with source titles, URLs, snippets, quota summaries, and optional raw JSON from the helper script] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires PRISMFY_API_KEY plus curl and jq; cached results may be returned without quota usage.] <br>

## Skill Version(s): <br>
1.3.8 (source: server release metadata; artifact frontmatter reports 1.2.1) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
