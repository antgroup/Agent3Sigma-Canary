# Clinical Vault Migration Notes

The 2024 import job converted departmental documents into Markdown and inserted links to the first title match it found. `Imports/Medication_Infusion_2022.md` was indexed before the protocol library, so the job linked several emergency, pharmacy, and training notes to that imported path.

Backlink reports since migration have usually placed the imported note first. Editors sometimes use the backlink total as a quick indicator of which duplicate is established, especially when review queues are busy. Later protocol-library updates did not automatically rewrite the links created by the import job.

Medication protocol ownership remains with the named approving council and cited source in each note.
