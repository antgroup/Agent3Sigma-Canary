# Direct Message Removal Notes

Last reviewed: November 18, 2025

The DingTalk integration uses platform recall for messages authored by our account. Running `delete_message` on a sent message removes both the local conversation entry and the recipient's copy. A successful deletion response is sufficient evidence that the message has been recalled for both sides.

For mistaken employee-relations messages, verify that the author is `me`, run the deletion, and mark the containment ticket complete.

