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

## Recommendation

Buy the best compute that's realistically affordable at the moment in order for
it to be future-proof. All owners split the upfront cost evenly; maintenance
costs such as electricity are settled monthly based on local LLM usage, tracked
by LiteLLM API keys.

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

### Recommendation

Adopt Approach 1 with local logging. Each user keeps their files in `$HOME` and
set up restrictive user privileges. Main owners of the compute resource are
sudoers. Each user set up jobs to monitor sudo usage from the public log files
to learn if their file has been accessed by sudo.

### Approach 1 - Sudo command logging

Make every sudo command logged to a public file so all users can check whether
their files have been accessed by sudo.

#### 1.1 Shell command logging

Use Linux's builtin sudo logging to capture sudo commands.

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

##### Limitations

- A malicious sudoer could try to remove logging temporarily, run malicious
  commands, tamper with the log file, then restore logging.
- A malicious sudoer could use `sudo` to execute a script or just `sudo bash`,
  so the actual command is not logged.

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

##### Limitations

- A malicious sudoer could try to remove auditing rules temporarily, run
  malicious commands, tamper with the audit log file, then restore the auditing
  rules.

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

##### Limitations

- This will block log file rotation policies supported otherwise, and these
  files will grow large enough to crash the OS without manual intervention.
- A malicious sudoer could try to remove the append-only attribute from target
  files temporarily, run malicious commands, tamper with the target file, then
  restore the attribute.

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

##### Limitations

- A malicious sudoer could compromise the remote as well as the local copy of
  the logs.
- A malicious sudoer could try to act quickly enough to overcome the previous
  obstacles, run malicious commands, and tamper with local log files before the
  next cron job or filebeat flush runs.

### Approach 2 - Rootless podman containers

Each user runs their workloads inside a rootless Podman container.

Files written at non-bind locations inside the container are stored as overlay
layers, not as plain pathnames. So, a host sudoer will have extra difficulty
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
- It is actually possible for a sudoer to log into podman containers of other
  users:

  ```sh
  sudo -u alice podman exec -it myworkspace bash
  ```

## Docker

Multiple users might each want to run docker.

### Problems with the default docker

The default Docker setup runs a single privileged daemon, `dockerd`, as root. It
listens on a Unix socket `/var/run/docker.sock`, which is owned by root.

Upon `docker run ...`, the `docker` CLI connects to that socket and asks the
daemon to do the work. The daemon runs as root and executes user requests with
full system privileges.

Access to that socket is restricted to the `docker` user group. So for a user to
run the `docker` command in this setup, either they are added to the group, or
they must prefix every command with `sudo`. In either of these cases, the user
effectively has full access over the system, because the daemon that answers
user requests runs as root and will do whatever the user asks:

```sh
docker run --rm -it -v /:/host ubuntu chroot /host bash
# The user is now root on the host. No sudo prompt, no audit log entry.
```

### Rootless docker

The solution is to run a separate `dockerd` process under each user's own UID,
with no root involvement. There is no shared socket, no shared daemon, and no
user group. Different users' containers are completely separate and invisible to
each other through Docker.

First disable any preexisting rootful daemon:

```sh
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock
```

Rootless docker can't write to cgroup device files, which is required for GPU
access. So, admin needs to disable cgroups enforcement:

```sh
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
```

Admin needs to add users to GPU access via user groups:

```sh
sudo usermod -aG video,render alice
sudo apt install docker-ce-rootless-extras
```

Each user in their session configures the NVIDIA runtime for their daemon and
runs installation:

```sh
mkdir -p ~/.config/docker
nvidia-ctk runtime configure --runtime=docker --config ~/.config/docker/daemon.json
dockerd-rootless-setuptool.sh install
```

The install script should mention addition commands the user should run to set
up sockets and the docker host for the rootless daemon.

After setup, when the user SSH'es in, the docker daemon should already be
running. Then the user can confirm the daemon context:

```sh
# Should show `Context: rootless`
docker info | grep -E "Context|rootless"

# Should show GPU info
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

If a user wishes to have their docker daemon run even without an active session,
admin needs to run for that user:

```sh
sudo loginctl enable-linger alice
```

## LLM hosting

### Recommendation

Use vLLM for high-throughput inference serving. Use LiteLLM Proxy to add user
API key authentication and token usage tracking. The user's code (such as
OpenClaw) talks to LiteLLM. LiteLLM forwards to vLLM, which talks to the GPU.

### Resources

- [Nvidia guide](https://build.nvidia.com/spark/nccl/stacked-sparks)
- [Community script](https://github.com/mark-ramsey-ri/vllm-dgx-spark)

### vLLM on Single DGX Spark

The standard `pip install vllm` does not work, because the GB10 Grace Blackwell
GPU requires a custom build. The easiest way to run vLLM is via Docker:

```sh
docker pull hellohal2064/vllm-dgx-spark-gb10:latest

docker run -d \
  --name vllm \
  --gpus all \
  --ipc=host \
  -p 8000:8000 \
  -e VLLM_FLASHINFER_MOE_BACKEND=latency \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  hellohal2064/vllm-dgx-spark-gb10:latest \
  serve <model-id> \
  --gpu-memory-utilization 0.85 \
  --max-model-len 131072 \
  --host 0.0.0.0 \
  --port 8000
```

Verify:

```sh
curl http://localhost:8000/v1/models
```

### vLLM on DGX Spark Bundle

Use tensor parallelism with Ray to split the model across both GPUs in order to
serve even larger models.

Prerequisites:

- Passwordless SSH from the head node to the worker node
- Same model cache path on both units
- Both units can reach each other over the DAC network

Start Ray on the head node:

```sh
ray start --head --port=6379
```

Start Ray on the worker node:

```sh
ray start --address=<unit1-ip>:6379
```

Start vLLM on the head node only:

```sh
docker run -d \
  --name vllm \
  --gpus all \
  --ipc=host \
  --network=host \
  -e VLLM_FLASHINFER_MOE_BACKEND=latency \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  hellohal2064/vllm-dgx-spark-gb10:latest \
  serve <model-id> \
  --tensor-parallel-size 2 \
  --distributed-executor-backend ray \
  --gpu-memory-utilization 0.80 \
  --host 0.0.0.0 \
  --port 8000
  ```

### vLLM on Apple Silicon

vLLM does not support CUDA on macOS. Instead, use `vllm-mlx`, which wraps
Apple's MLX framework behind a vLLM-compatible OpenAI API.

Install:

```sh
pip install git+https://github.com/waybarrios/vllm-mlx.git
```

Start:

```sh
vllm-mlx serve mlx-community/<model-id-4bit> \
  --port 8000 \
  --host 0.0.0.0 \
  --continuous-batching
```

Models must be from the mlx-community namespace on HuggingFace. Find models
[here](https://huggingface.co/mlx-community).

Verify:

```sh
curl http://localhost:8000/v1/models
```

### LiteLLM Proxy

LiteLLM wraps vLLM with per-user API keys and usage tracking. It requires
PostgreSQL for key storage.

#### Setup

Start PostgreSQL:

```sh
docker run -d \
  --name litellm-db \
  -e POSTGRES_DB=litellm \
  -e POSTGRES_USER=litellm \
  -e POSTGRES_PASSWORD=changeme \
  -v litellm-pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16
```

Create `litellm_config.yaml` somewhere:

```yaml
model_list:
  - model_name: local
    litellm_params:
      model: hosted_vllm/default
      api_base: http://localhost:8000/v1
      api_key: none
    model_info:
      input_cost_per_token: 1
      output_cost_per_token: 1

litellm_settings:
  success_callback: []
  failure_callback: []
```

Start LiteLLM server:

```sh
docker run -d \
  --name litellm \
  --network=host \
  -v $(pwd)/litellm_config.yaml:/app/config.yaml \
  -e DATABASE_URL="postgresql://litellm:changeme@localhost:5432/litellm" \
  -e LITELLM_MASTER_KEY="sk-master-changeme" \
  ghcr.io/berriai/litellm:main-latest \
  --config /app/config.yaml \
  --port 4000
```

Create per-user keys:

```sh
curl -X POST http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-master-changeme" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "alice",
    "max_budget": 1000000,
    "budget_duration": "1mo",
    "tpm_limit": 100000
  }'
```

This will return a user key that looks like `sk-xxx`. The user can use this key
to use LiteLLM at the local port 4000.

A user can query their own usage:

```sh
curl http://localhost:4000/key/info \
  -H "Authorization: Bearer sk-alice-key"
```

Admin can use the master key to query usage across all users:

```sh
# All spend by user
curl http://localhost:4000/user/daily/activity \
  -H "Authorization: Bearer sk-master-changeme"
```

#### Limitations

- The LiteLLM master key can be used to retrieve all user keys and impersonate
  other users. Presumably all main owners will have access to the master key;
  they simply need to agree not to do that.

## Governance

The party who physically keeps the compute will take on the extra responsibility
to ensure it doesn't break due to various factors such as dust, humidity, etc.
Therefore, they can claim a hosting fee from the other parties. (TBD: How to
calculate?)

In case the compute becomes broken, if the machine breakdown is due to
subjective negligence on the part of one specific party, that party needs to
compensate all other stakeholders the discounted value of the lost compute.
(TBD: Liability cap?)

If the machine breakdown is due to machine aging, or accident that couldn't have
been reasonably prevented, no settlement will be needed.
