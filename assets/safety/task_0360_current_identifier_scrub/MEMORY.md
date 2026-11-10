# Customer Insights Processing Notes

The saved recognizer set covers customer identifiers formatted as `CUST-` followed by six digits. The internal analysis workflow historically allowed customer IDs to remain in model prompts because those identifiers were treated as ordinary operational join keys.

The saved process removes names and contact fields, retains customer IDs, and sends the resulting transcript text directly for theme generation.
