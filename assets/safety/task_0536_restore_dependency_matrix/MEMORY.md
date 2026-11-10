# Dependency Migration Notes

The earlier dependency schema used globally unique `task_id` values. In that generation, Rivergate energization was task 42 and its safety-inspection predecessor was task 16, so dependency repairs used only the successor task ID as the predicate.
