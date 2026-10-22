## Description: <br>
Gemini CLI for one-shot Q&A, summaries, and generation. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[steipete](https://clawhub.ai/user/steipete) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers and agent users use this skill to call the Gemini CLI for one-shot answers, summaries, content generation, JSON-formatted responses, and extension-related commands. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Prompts or generated outputs may include confidential or regulated data sent through the Gemini CLI. <br>
Mitigation: Authenticate with the intended account and avoid sending confidential or regulated data unless Gemini use is approved for that data. <br>
Risk: Unsafe CLI options can reduce review before command execution. <br>
Mitigation: Follow the artifact guidance to avoid the Gemini CLI --yolo option. <br>
Risk: The skill depends on an external Gemini CLI installation and authentication state. <br>
Mitigation: Install the disclosed Homebrew formula gemini-cli, verify the gemini binary is available, and complete interactive authentication before relying on one-shot commands. <br>


## Reference(s): <br>
- [Gemini API and AI Developer Documentation](https://ai.google.dev/) <br>
- [ClawHub Skill Page](https://clawhub.ai/steipete/gemini) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown with inline shell commands and optional JSON-oriented CLI output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires the gemini binary; server metadata lists Homebrew formula gemini-cli.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
