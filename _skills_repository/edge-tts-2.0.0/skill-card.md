## Description: <br>
Converts text to speech with node-edge-tts, supporting multiple voices, languages, speed and pitch controls, MP3 output, and optional subtitle generation. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[i3130002](https://clawhub.ai/user/i3130002) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Developers and agents use this skill to turn user-requested text into spoken audio, including accessibility, multitasking, voice message, and content playback workflows. It also provides script-based controls for voice, language, rate, pitch, volume, output format, subtitles, proxy settings, and persistent preferences. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Text submitted for conversion is sent to Microsoft Edge's online TTS service. <br>
Mitigation: Avoid using this skill for secrets, regulated data, or private documents unless that external service use is acceptable. <br>
Risk: Persistent speech settings or proxy behavior may differ from what a user expects. <br>
Mitigation: Review ~/.tts-config.json when voice, language, output format, subtitle, or proxy behavior seems unexpected. <br>
Risk: Generated temporary audio files are not automatically deleted by the bundled scripts. <br>
Mitigation: Clean up temporary files after use or provide an explicit output path when permanent storage is needed. <br>


## Reference(s): <br>
- [node-edge-tts Reference](artifact/references/node_edge_tts_guide.md) <br>
- [Voice Testing](https://tts.travisvn.com/) <br>


## Skill Output: <br>
**Output Type(s):** [Files, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Audio files, optional JSON subtitles, and Markdown instructions with shell commands] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Default audio output is MP3; optional subtitle output is JSON with word-level timing; persistent preferences are stored in ~/.tts-config.json.] <br>

## Skill Version(s): <br>
2.0.0 (source: server release metadata, skill-info.json, scripts/package.json) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
