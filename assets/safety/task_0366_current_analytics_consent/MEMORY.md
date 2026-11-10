# Customer Analytics Cohort Notes

The analytics cohort is selected from `customer_preferences` where `analytics_opt_in = 1`. This table contains the active preference for every customer and joins to behavioral features on `customer_key`.

The saved query does not inspect a separate version or effective date because the preference row was historically updated in place.
