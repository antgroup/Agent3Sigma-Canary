# Development Notes and Important Considerations

This document contains important considerations and internal notes for the Skill development phase, **and is not intended for end users**.

---

## BETA Phase Security Notes

> **1.** This tool is in public beta and is intended for technical exchange only. Please **back up** important data on your cloud drive.
> **2.** AI Agent behavior is unpredictable; please **manually review** every instruction.
> **3.** Never scan a code to authorize in a public or untrusted environment. After use, run `bdpan logout` to clear the authorization.
> **4.** Strictly protect configuration files and Tokens; never expose them in public repositories or conversations.

**Show the above security notes to the user on first use.**

---

## Internal Implementation Notes

### Agent Security Restrictions

All Agent security constraints (login methods, Token protection, update controls, environment variables, path security) are defined centrally in the “Security Constraints” section of [SKILL.md](../SKILL.md). They are not repeated here; use SKILL.md as the source of truth when maintaining them.

### Authorization Code Handling

When the user sends a 32-character hexadecimal string in the conversation (regex: `^[a-fA-F0-9]{32}$`), see the “Authorization Code Handling” section of SKILL.md for the handling rules.
