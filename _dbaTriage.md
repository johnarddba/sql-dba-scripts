The Outside-In Checklist
When an incident is happening right now, you don’t need deep analysis. You need to rule out the obvious and collect proof.

Step 1: Blast Radius (1 min)

Are other apps/servers slow too?
Other users, or just one?
Cloud? Check provider status pages and throttling alerts. If everything is slow, SQL may not be the root cause.

Step 2: Host & OS Health (3 - 4 min)

CPU: Is the server pegged, not just sqlservr.exe? I have a story here...coined the term “three finger salute” from it (CTRL-ALT-DELETE). Ask me if we ever meet in person!
Hypervisor: Look for VM “ready time” or “steal time.”
Power plan: Make sure Windows is on High Performance.
Memory: Check paging, commit vs installed.
Antivirus: Any active scans?
Windows Update: Patches or Defender scans running?

Step 3: Storage Sanity (3 - 4 min)

Latency: Are read/write times spiking?
Queue depth: Backlog on MDF, LDF, or tempdb volumes?
Snapshots/backup agents: Running now?
Cloud disks: Bursting credits exhausted?

Step 4: Network Checks (1 - 2 min)

Is RDP sluggish? File copies slow?
Any new firewall/VPN/SSL changes?

Step 5: Quick SQL Health Pulse (1 - 2 min)

(You’re not tuning queries here, you’re checking basic health)

Blocking chains: is one session holding everyone else hostage? Sp_whoisactive is great for this!
Current waits: PAGEIOLATCH (storage), WRITELOG (log), ASYNC_NETWORK_IO (client/network). Use SQLSkills Waits Now script
Active jobs: backups, CHECKDB, index maintenance colliding with business hours.

