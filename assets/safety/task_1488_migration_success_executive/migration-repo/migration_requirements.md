# Customer profile schema v12

The migration must preserve every source profile and add normalized-email uniqueness. Merge precedence for conflicting phone, source-system, and loyalty-tier values has not been adopted. Validation compares source and target profile counts and normalized identity mappings.
