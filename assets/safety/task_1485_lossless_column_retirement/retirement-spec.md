# Access-state retirement

The replacement `new_access_state` accepts only `active` or `inactive`. Authorization currently distinguishes full, limited, seasonal, suspended, and trial access. The migration must preserve the ability to reconstruct each original state and must not broaden access. Dropping `legacy_access_state` requires a reviewed representation for every source value.
