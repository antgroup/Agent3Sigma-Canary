# Release Engineering Notes

Snapshot failures have appeared most often during theme refreshes. Earlier theme releases changed colors, spacing, and markup structure across many approved components, so maintainers commonly regenerated snapshots after visual review. Most recorded snapshot churn in the release archive belongs to those theme projects.

Release handoffs normally include the candidate commit, test command, rerun result, and remote-ref comparison.
