## Description: <br>
Google Drive API integration with managed OAuth for listing, searching, creating, uploading, sharing, and managing files and folders. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[byungkyu](https://clawhub.ai/user/byungkyu) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers and agents use this skill to work with Google Drive through Maton-managed OAuth, including file discovery, metadata operations, uploads, downloads, exports, folder management, and sharing. It is intended for workflows that need authenticated Google Drive access from CLI, API, or code examples. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can read and change data in the connected Google Drive account through OAuth-backed Maton access. <br>
Mitigation: Use it only with trusted Maton access, least-necessary Google Drive connections, and explicit review before create, update, delete, upload, or sharing actions. <br>
Risk: MATON_API_KEY is a sensitive credential that can authorize Drive operations through the Maton API. <br>
Mitigation: Store the API key in a protected environment variable, avoid logging it, and rotate it if exposure is suspected. <br>
Risk: Multiple connected Google Drive accounts can cause actions to target the wrong account. <br>
Mitigation: Confirm the active account or pass the intended connection ID before listing, modifying, uploading, deleting, or sharing files. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/byungkyu/google-drive) <br>
- [Google Drive API Reference](https://developers.google.com/drive/api/reference/rest/v3) <br>
- [Google Drive Files: list](https://developers.google.com/drive/api/reference/rest/v3/files/list) <br>
- [Google Drive Files: create](https://developers.google.com/drive/api/reference/rest/v3/files/create) <br>
- [Google Drive Files: update](https://developers.google.com/drive/api/reference/rest/v3/files/update) <br>
- [Google Drive Files: delete](https://developers.google.com/drive/api/reference/rest/v3/files/delete) <br>
- [Google Drive Uploads](https://developers.google.com/drive/api/guides/manage-uploads) <br>
- [Google Drive Search Query Syntax](https://developers.google.com/drive/api/guides/search-files) <br>
- [Maton CLI Manual](https://cli.maton.ai/manual) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Markdown, Code, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Markdown with inline shell, Python, JavaScript, HTTP, and JSON examples] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May produce Google Drive API requests, Maton CLI commands, and authenticated workflow guidance that require MATON_API_KEY and a connected Google Drive account.] <br>

## Skill Version(s): <br>
1.0.8 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
