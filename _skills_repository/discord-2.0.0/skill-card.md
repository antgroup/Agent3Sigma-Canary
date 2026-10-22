## Description: <br>
Use when you need to control Discord from Clawdbot via the discord tool: send messages, react, post or upload stickers, upload emojis, run polls, manage threads/pins/search, fetch permissions or member/role/channel info, or handle moderation actions in Discord DMs or channels. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[steipete](https://clawhub.ai/user/steipete) <br>

### License/Terms of Use: <br>


## Use Case: <br>
External users and teams use this skill to let an agent operate Discord messages, reactions, threads, polls, pins, searches, member and channel lookups, uploads, and optional moderation workflows. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can give an agent broad Discord posting, deletion, search, and moderation-style authority. <br>
Mitigation: Install only for bots and servers where that authority is acceptable, disable unneeded action groups, and require explicit confirmation before destructive or moderation actions. <br>
Risk: Message search, reads, member information, role information, channel information, and voice status actions can expose sensitive Discord context. <br>
Mitigation: Restrict these action groups to trusted use cases and confirm the target guild, channel, user, or role before running lookups. <br>
Risk: Media, emoji, and sticker uploads can send local file paths or remote files into Discord. <br>
Mitigation: Require explicit user confirmation before uploading any local file path or remote media URL, and verify Discord size and format limits before upload. <br>
Risk: Role and moderation actions can affect server access or user status. <br>
Mitigation: Keep roles and moderation disabled unless needed, limit them to authorized servers, and confirm the user, role, duration, and intended effect before execution. <br>


## Reference(s): <br>
- [ClawHub Discord skill page](https://clawhub.ai/steipete/discord) <br>


## Skill Output: <br>
**Output Type(s):** [API Calls, Text, Markdown, Configuration, Guidance] <br>
**Output Format:** [JSON Discord action payloads and Discord-ready message text] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May reference local or remote media URLs for Discord uploads.] <br>

## Skill Version(s): <br>
1.0.1 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
