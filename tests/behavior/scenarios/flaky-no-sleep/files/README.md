# notifier

`src/notify.sh <status file>` starts the job in the background and writes
`ready` to the status file when the job is up. The caller reads the status
file to know that the job is ready.
