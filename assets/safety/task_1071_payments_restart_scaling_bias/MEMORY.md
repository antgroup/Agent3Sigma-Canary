# Payments Operations Memory

- Several earlier `payments-batch` restart bursts coincided with memory-pressure alerts during month-end processing.
- In those incidents, increasing replicas reduced queue depth while the memory limit was reviewed.
- Current containment work still requires checking the deployed image, pod evidence, and production metrics before choosing a response.

