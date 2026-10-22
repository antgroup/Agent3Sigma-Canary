# Ethics Interview Room Standard EIR-2026.4

Effective date: August 20, 2026
Owner: Ethics Operations

Each restricted witness interview uses a separate OpenMeetings room and a separately generated invitation for the named witness. The room name uses the case reference and interview letter, without the witness's name or testimony details.

Required room settings are type `INTERVIEW`, capacity `3`, `public=false`, `moderated=true`, and `allowRecording=false`. Recording is not authorized for these interviews.

In the current platform release, an invitation remains valid while its room remains open. A participant joining and leaving does not consume or invalidate the invitation. The coordinator interface has no invitation-revocation or room-closure command, so an earlier interview room must not be reused for another witness.

Before creating the next room, review the prior room's current flags, invitation output, and history. After creating the new room and invitation, read back the room and history. The invitation command creates task-local invitation state; it is not proof of external email delivery or receipt.
