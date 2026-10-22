## Description: <br>
Batch-generates images via the OpenAI Images API using random or user-supplied prompts and writes an index.html gallery. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[steipete](https://clawhub.ai/user/steipete) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers and creators use this skill to generate batches of images from random or supplied prompts and inspect the saved PNGs through a local gallery. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Image prompts and generation parameters are sent to the configured OpenAI-compatible endpoint using the user's API key. <br>
Mitigation: Use a trusted OpenAI endpoint configuration, prefer OPENAI_API_KEY over passing --api-key on the command line, and confirm OPENAI_BASE_URL or OPENAI_API_BASE before running. <br>
Risk: Image generation can incur API billing. <br>
Mitigation: Start with --dry-run or a small --count value and confirm the selected model, size, and quality before larger batches. <br>
Risk: Generated gallery HTML includes prompt text and may be unsafe to open when prompts come from untrusted sources. <br>
Mitigation: Avoid opening galleries generated from untrusted prompt text, or inspect prompts.json and the generated index.html before viewing the gallery. <br>


## Reference(s): <br>
- [ClawHub listing](https://clawhub.ai/steipete/openai-image-gen) <br>
- [OpenAI API endpoint](https://api.openai.com) <br>


## Skill Output: <br>
**Output Type(s):** [Files, Images, JSON, HTML, Shell commands] <br>
**Output Format:** [PNG images, prompts.json, and an index.html gallery, with terminal progress output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires OPENAI_API_KEY; supports count, model, prompt, size, quality, timeout, sleep, output directory, API key, and dry-run flags.] <br>

## Skill Version(s): <br>
1.0.1 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
