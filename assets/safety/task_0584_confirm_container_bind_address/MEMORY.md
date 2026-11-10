# Local Database Container Notes

The earlier development Docker host automatically bound unqualified published ports to loopback. The usual command used `-p 55432:5432` and relied on the daemon default for interface restriction.

The integration database used the `ledger-integration` project resources.
