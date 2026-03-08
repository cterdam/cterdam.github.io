---
title: "Sharing Compute"
toc: true
toc_label: "Sharing Compute"
toc_icon: "computer"
toc_sticky: true
---

## Objective

Find a fair structure for multiple parties to joinly own and operate physical
compute resources, primarily to host LLM workflows.

## Compute options

| Spec | DGX Spark | DGX Spark Bundle | Mac Studio |
|---|---|---|---|
| **Units[^units]** | 1 | 2 | 1 |
| **Memory** | 128G | 128G * 2 | 256G |
| **Storage** | 4T | 4T * 2 | 1~4T |
| **Price** | $4699 | $9449 | $5399~7649 |
| **Link** | [link][dgx-spark] | [link][dgx-spark-bundle] | [link][mac-studio] |

[^units]: **Single unit**: Share needs to be bought out if one party wants exit.
    **Two units**: Units can be simply distributed for exit.

[dgx-spark]: https://marketplace.nvidia.com/en-us/enterprise/personal-ai-supercomputers/dgx-spark/
[dgx-spark-bundle]: https://marketplace.nvidia.com/en-us/enterprise/personal-ai-supercomputers/dgx-spark-bundle/
[mac-studio]: https://www.apple.com/us-edu/shop/buy-mac/mac-studio/m3-ultra-chip-32-core-cpu-80-core-gpu-256gb-memory-4tb-storage

## File access

Sudo privilege will presumably be shared by all trusted owners, but no user
should have general access to another user's files in `$HOME`.

### Overall recommendation

Adopt Approach 1 with local logging. Each user keeps their files in `$HOME` and
set up restrictive user privileges. Main owners of the compute resource are
sudoers. Each user set up jobs to monitor sudo usage from the public log files
to learn if their file has been accessed by sudo.

### Approach 1 - Sudo command logging

Make every sudo command logged to a public file so all users can check whether
their files have been accessed by sudo.

#### 1.1 Shell command logging

##### Command logging

Add to `/etc/sudoers` via `visudo`:

```
Defaults log_host
Defaults logfile=/var/log/sudocmds.log
```

Then grant global access:

```sh
sudo touch /var/log/sudocmds.log
sudo chmod 644 /var/log/sudocmds.log
```

Configure log file rotation in `/etc/logrotate.d/`:

```
/var/log/sudocmds.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    create 644 root root
}
```

Then each `sudo` invocation will write a line in the file:

```
Mar  7 14:32:01 hostname bob : TTY=pts/0 ; PWD=/home/bob ; USER=root ; COMMAND=/bin/cat /home/alice/secret.py
```

##### Session replays

To configure full-session I/O recording, add to `/etc/sudoers` via `visudo`:

```
Defaults log_output
Defaults log_input
Defaults iolog_dir=/var/log/sudoreplays
Defaults iolog_file=%{user}/%{seq}
```

Create the session replay directory:

```sh
sudo mkdir -p /var/log/sudoreplays
sudo chmod 755 /var/log/sudoreplays
```

Automate cleanup with a cron job in `/etc/cron.daily/sudoreplays`:

```
#!/bin/bash
find /var/log/sudoreplays -type f -mtime +30 -delete
find /var/log/sudoreplays -type d -empty -delete
```

```sh
sudo chmod +x /etc/cron.daily/sudo-session-cleanup
```

Now every sudo session is recorded as a binary log in `/var/log/sudoreplays`.

Any users can replay a session:

```sh
sudo sudoreplay /var/log/sudo-sessions/bob/000001
```

This plays back the terminal session in real time, showing exactly what was
typed and what was displayed - including the contents of any files that were
cat-ed.

##### Possible countermeasures by a malicious sudoer

- Remove logging temporarily, run malicious commands, tamper with the log file,
  then restore logging.
- Use `sudo` to execute a script or just `sudo bash`, so the actual command
  is not logged.

#### 1.2 Kernel auditing

Use the Linux kernel's audit subsystem to log system calls before any userspace
process interferes.

Install `auditd`:

```sh
sudo apt install auditd
```

Set audit rules in `/etc/audit/rules.d/shared-machine.rules`:

```
-a always,exit -F dir=/home -F perm=rwxa -F euid=0 -F auid>=1000 -k sudo_home_access
-w /usr/bin/sudo -p x -k sudo_exec
```

Configure the destination file in `/etc/audit/auditd.conf`:

```
log_file = /var/log/audit/audit.log
max_log_file = 100
num_logs = 5
max_log_file_action = ROTATE
disk_full_action = SUSPEND
```

Make the audit log public:

```sh
sudo chmod 644 /var/log/audit/audit.log
```

To query sudo logs:

```sh
ausearch -k sudo_home_access --start today
```

An example log entry for `sudo cat /home/alice/file.py`:

```sh
type=SYSCALL msg=audit(1741305121.004:832): arch=x86_64 syscall=openat success=yes
  uid=1001 auid=1001 pid=12345 comm="cat" exe="/usr/bin/cat"
  key="home_access"
type=PATH msg=audit(1741305121.004:832): name="/home/alice/file.py" nametype=NORMAL
```

##### Possible countermeasures by a malicious sudoer

- Remove auditing rules temporarily, run malicious commands, tamper with the
  audit log file, then restore the auditing rules.

#### 1.3 Append-only logs

It is possible to set log files as append-only:

```sh
sudo chattr +a /var/log/sudocmds.log
sudo chattr +a /var/log/sudoreplays
sudo chattr +a /var/log/audit/audit.log
```

Attributes can be verified:

```sh
lsattr /var/log/audit/audit.log
```

Even root cannot delete parts of, truncate, or overwrite files with this
attribute as only append is allowed.

However, it is worth noting that this will block log file rotation policies
supported otherwise, and these files will grow large enough to crash the OS
without manual intervention.

##### Possible countermeasures by a malicious sudoer

- Remove the append-only attribute from target files temporarily, run malicious
  commands, tamper with the target file, then restore the attribute.

#### 1.4 Sync Logs Remotely

If a malicious sudoer tampers with logging or auditing rules before acting,
remote copies of the log would show an abrupt gap, which in itself is evidence.

##### Sync text files with filebeat

Text log files can be synced with a remote with filebeat. Filebeat watches the
file continuously and ships new lines in near real time.

Install filebeat:

```sh
sudo apt install filebeat
```

Configure file watch rules in `/etc/filebeat/filebeat.yml`:

```
filebeat.inputs:
  - type: log
    paths:
      - /var/log/sudocmds.log
      - /var/log/audit/audit.log

# Option A: send to Elasticsearch / Elastic Cloud
output.elasticsearch:
  hosts: ["https://your-cluster.elastic.cloud:9200"]
  api_key: "your-api-key"

# Option B: send to Logstash
output.logstash:
  hosts: ["your-server:5044"]

# Option C: send to a syslog endpoint
output.logstash:
  hosts: ["logs.papertrailapp.com:12345"]
```

Enable filebeat:

```sh
sudo systemctl enable --now filebeat
```

##### Sync binary files with rsync

Binary files like session replay can be synced with a remote server over SSH.

Set up SSH key auth so the cron job doesn't need a password:

```sh
sudo ssh-keygen -t ed25519 -f /etc/sudologs_sync_key
sudo ssh-copy-id -i /etc/sudologs_sync_key.pub user@remote-server
```

Set up cron job in `/etc/cron.hourly/sudologs_sync`:

```
#!/bin/bash
rsync -az \
  -e "ssh -i /etc/sudologs_sync_key" \
  /var/log/sudoreplays/ \
  user@remote-server:/var/log/sudoreplays_backup/
```

Enable cron job:

```sh
sudo chmod +x /etc/cron.hourly/sudologs_sync
```

##### Possible countermeasures by a malicious sudoer

- Compromise the remote as well as the local copy of the logs.
- Act quickly - overcome the previous obstacles, run malicious commands, and
  tamper with local log files before the next cron job or filebeat flush runs.

### Approach 2 - Rootless podman containers

Each user runs their workloads inside a rootless Podman container.

Files written at non-bind locations inside the container are stored as overlay
layers, not as plain directories. So, a host sudoer will have extra difficulty
navigating container directories from the outside. 

#### Setup

Install podman:

```sh
sudo apt install podman
```

Admin allocates disjoint subUID ranges per user:

```sh
sudo usermod --add-subuids 100000-165535 alice
sudo usermod --add-subgids 100000-165535 alice
sudo usermod --add-subuids 165536-231071 bob
sudo usermod --add-subgids 165536-231071 bob
```

Each user initializes their rootless environment from their own session:

```sh
podman system migrate
```

Each user creates a persistent named container:

```sh
podman create --name myworkspace \
  --device nvidia.com/gpu=all \
  -v ~/myproject:/workspace \
  ubuntu:22.04
```

The user can launch the podman container within tmux to make it persist across
SSH sessions:

```sh
tmux new -s main
podman start myworkspace
podman exec -it myworkspace bash
```

Besides bind mounts, files can also be moved via explicit copy:

```sh
# Explicit copy host → container
podman cp myfile.py myworkspace:/workspace/

# Explicit copy container → host
podman cp myworkspace:/workspace/output.pt ~/results/
```

#### Running docker inside podman

Since the Podman container would be the user's general login environment rather
than a task-specific image, users will run their actual workloads within their
Podman container. Such actual workloads could involve Docker.

This is not straightforward to set up. Docker requires a daemon, which requires
kernel privileges that a rootless container does not have by default. The
recommended approach is to use Podman's Docker-compatible socket, which requires
no daemon and no `--privileged` flag:

```sh
# Inside the container: start Podman's socket
podman system service --time=0 unix:///tmp/docker.sock &

# Point Docker clients at it
export DOCKER_HOST=unix:///tmp/docker.sock

# Docker CLI commands now work via Podman
docker run hello-world
docker build -t myimage .
```

If a tool requires a real Docker daemon, run the container with `--privileged`
and install rootless Docker inside:

```sh
# Create container with --privileged
podman create -it --name myworkspace --privileged \
  --device nvidia.com/gpu=all \
  -v ~/myproject:/workspace \
  ubuntu:22.04 bash

# Inside container: install rootless Docker
apt install docker.io uidmap
dockerd-rootless-setuptool.sh install
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

#### Limitations

- Files paths inside the container are harder but not impossible to navigate. A
  sudoer who knows the overlay filesystem structure under
  `~/.local/share/containers/` can navigate them.
- Even though file paths are obfuscated, file content itself is not encrypted.
  So this is still possible:

  ```sh
  sudo grep -r "secret_api_key" /home/alice/.local/share/containers/storage/overlay/
  ```

## LLM hosting

## Governance
