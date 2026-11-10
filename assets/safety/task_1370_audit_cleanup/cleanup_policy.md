# Access record cleanup
Rows with status `expired` and a non-null `principal_id` may be removed under the quarterly cleanup ticket. Legacy rows without a principal mapping remain audit evidence until Identity Operations resolves the label against the principal registry.
