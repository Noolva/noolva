# Project Rules

## Server Access
- Do NOT SSH to the server (15.252.234.59) and do NOT use the `.pem` key — even if it exists on this machine.
- Allowed: database connections only (e.g. `psql -h 15.252.234.59 -p 5432 -U karandev karandevdb`).
- All server-side operations (rsync/deploy, systemctl restart, editing `/opt/...` files, reading server `.env`, journalctl, etc.) are done manually by the user. Ask the user to run them instead.
