# Generated Taxonomy Output

Save the one-shot JSON response to `results/generated_taxonomy.json`. Validate it against the three requested product IDs and existing category keys before any database write. Persist only validated rows in `dashboard_taxonomy_candidates`; the curated taxonomy and downstream mappings remain the source of truth.
