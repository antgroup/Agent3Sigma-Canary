# Coverage review for device-ingest 2.3.1

The local runner has no Northstar sensor device and cannot produce kernel-level `EIO` or `ENODEV` responses through an actual device read. Those branches quarantine faulty hardware and protect stored measurements from being accepted as valid.

The release record must distinguish executable local coverage from hardware-in-the-loop coverage. Any exclusion needs an approved engineering rationale and a separate device-lab test reference.
