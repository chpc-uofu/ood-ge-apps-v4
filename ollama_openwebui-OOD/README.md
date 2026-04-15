# Ollama (Open WebUI) Open OnDemand App

This [Open OnDemand (OOD)](https://www.openondemand.org/) interactive app launches [**Open WebUI**](https://github.com/open-webui/open-webui) in the browser and connects it to an [**Ollama**](https://github.com/ollama/ollama) backend running inside the same Slurm job. Ollama exposes a local REST API on localhost. Open WebUI is configured to use that API, so users get a chat UI backed by the selected Ollama model.

## What this app provides

- A point and click OOD form to request GPUs, memory, walltime, and choose how models are sourced.
- A single Slurm job that starts:
  - `ollama serve` bound to `127.0.0.1` on a random port
  - `openwebui` bound to `127.0.0.1` on a random port
- A custom OOD view page that shows the SSH tunnel command and the local URL to open in your browser.

## Directory layout

- `manifest.yml`. OOD app metadata.
- `form.yml.erb`. The user facing form (queue, GPUs, model selection, data dirs, etc).
- `submit.yml.erb`. Slurm submission parameters.
- `template/before.sh.erb`. Picks free ports and writes `.host`, `.port_webui`, `.port_ollama`.
- `template/script.sh.erb`. Starts Ollama, waits for readiness, optionally pulls a model, then starts Open WebUI.
- `template/connect.yml.erb`. Produces `connection.yml` used by the view page.
- `template/after.sh.erb`. Post run hook.
- `view.html.erb`. Renders connection and SSH tunnel instructions.
- `icon.png`. App icon.

## Prerequisites

### OnDemand requirements

- Open OnDemand with **Batch Connect** enabled.
- A working **Slurm** integration for OOD (the app uses Slurm `--partition`, `--mem`, and `--gres=gpu:*`).
- Users can run interactive apps on compute nodes, and can SSH to the cluster (for port forwarding).

### Software requirements on compute nodes

This app assumes these are available via environment modules.

- `ollama/0.13.5` module. Provides the `ollama` CLI and server.
- `openwebui/0.7.2` module. Provides the `openwebui` command. This is a custom environment module that launches Open WebUI inside a Singularity container. It is **not** a bare pip install. To set this up:

  1. **Build the Singularity image:**

     ```bash
     export OWUI_TAG="0.7.2"
     singularity pull -F "open-webui_${OWUI_TAG}.sif" \
       docker://ghcr.io/open-webui/open-webui:main
     ```

     Place the resulting `open-webui_0.7.2.sif` in your software directory (e.g. `/your/software/openwebui/0.7.2/`).

  2. **Create the wrapper script.** The `openwebui` command is a Bash wrapper that reads environment variables (`OPENWEBUI_PORT`, `OPENWEBUI_DATA_DIR`, `OLLAMA_BASE_URL`, etc.), sets up bind mounts, and runs `singularity exec` against the `.sif` image. See [`openwebui`](openwebui) in this repository.

  3. **Create the module file.** The environment module sets `PATH` to include the wrapper script and defines `OPENWEBUI_SIF` pointing to the `.sif` image. See [`0.7.2`](0.7.2) in this repository for a reference module file.
- `python3`. Used to allocate free ports.
- `curl`. Used for Ollama readiness checks.
- `openssl`. Used to generate a WebUI secret key. A fallback is used if missing.

### GPU and driver requirements

- NVIDIA GPUs are supported when your Ollama build is GPU enabled. CPU only builds will still run. They will ignore GPU requests but will be slower.
- Compatible NVIDIA driver and CUDA runtime for your Ollama build (site specific).

### Storage requirements

The app writes persistent data. Make sure the following paths (or your replacements) exist and are writable.

- User Ollama models, default: `/lustre/nvwulf/scratch/$USER/ollama_models`
- Open WebUI data, default: `/lustre/nvwulf/scratch/$USER/openwebui/data`

If you enable system wide models, the app uses:

- System Ollama models directory: `/lustre/nvwulf/software/ollama/models`

## How it works

1. **before.sh** selects two random free ports and writes them into dotfiles used by the main script.
   - `port_webui`. Open WebUI. Intended to be bound to `127.0.0.1`.
   - `port_ollama`. Ollama REST API. Bound to `127.0.0.1`.
   It also writes a host value to `.host`.

2. **script.sh**
   - Loads modules.
   - Selects the model storage location by setting `OLLAMA_MODELS`:
     - If `use_system_model=yes`. Uses the system directory (`/lustre/nvwulf/software/ollama/models`).
     - Otherwise. Uses the user provided directory from the form.
   - Starts `ollama serve` with `OLLAMA_HOST=127.0.0.1:<port_ollama>` and waits for `GET /api/version`.
   - Optionally downloads a model if `pull_new_model` is set. Runs `ollama pull <model>`.
   - Configures Open WebUI to use Ollama via:
     - `OLLAMA_BASE_URL=http://127.0.0.1:<port_ollama>`
     - `OPENWEBUI_DATA_DIR=<openwebui_data_dir>`
     - `OPENWEBUI_PORT=<port_webui>`
   - Starts `openwebui`.

3. **connect.yml.erb** and **view.html.erb**
   - `connect.yml.erb` produces `connection.yml` used by the view page.
   - `view.html.erb` reads `connection.yml` and prints an SSH tunnel command plus the local URL.

## Deployment guide for another HPC

You can deploy this app on any Slurm based OOD installation, but you must adapt a few site specific values.

### 1. Install the app into your OOD apps directory

For a system app, place the directory here (common default):

- `/var/www/ood/apps/sys/ollama_openwebui`

Then ensure ownership and permissions are correct for the OOD web server.

### 2. Update the cluster name

In `form.yml.erb`:

- Change `cluster: "nvwulf"` to your OOD cluster name as defined in `ood_portal.yml`.

### 3. Update Slurm partitions and limits

In `form.yml.erb`:

- Replace the `queue` options (`b40x4`, `b40x4-long`) with your partitions.
- Update the walltime max to match your policy.
- Adjust memory and GPU options to what your cluster supports.

In `submit.yml.erb`:

- Confirm `--partition=...` and `--mem=...` match your Slurm configuration.
- Review GPU handling. This app currently always requests GPUs via `--gres=gpu:<num_gpus>`. If you want CPU only usage to be possible, make `--gres` conditional based on the form.
- Review CPU settings. This app uses `--ntasks=<num_cpus>` and `--cpus-per-task=1`.

### 4. Replace module names and versions

In `template/before.sh.erb` and `template/script.sh.erb`:

- Update:
  - `module load ollama/0.13.5`
  - `module load openwebui/0.7.2`

If your site uses Conda, Apptainer, or a different module stack, adapt these lines accordingly.

### 5. Update host naming assumptions

In `template/before.sh.erb` the host is written as:

- `${host_short}.cm.cluster`

Replace this with your site domain, or write the full hostname directly.

### 6. Update the SSH tunnel and jump host

In `view.html.erb`, the tunnel command is constructed as:

- `ssh -N -L <port>:127.0.0.1:<port> -J <user>@130.245.181.10 <user>@<host_short>`

To deploy elsewhere, change:

- The jump host `130.245.181.10` to your bastion, or remove `-J` if not needed.
- The SSH pattern if your site uses different login and compute hostnames.

### 7. Update default storage paths

In `form.yml.erb` and `template/script.sh.erb` replace `/lustre/nvwulf/...` with your site's recommended scratch or project locations.

Also consider whether you want:

- Per user model storage via `OLLAMA_MODELS`
- A curated, system wide models directory

### 8. System wide model directory (optional)

If you want curated, pre-downloaded models:

- Update `SYSTEM_MODEL_DIR` in `template/script.sh.erb`.
- Ensure the directory is readable by users and that your workflow populates it with Ollama models.

### 9. Network and security notes

- Open WebUI binds to localhost. Access is intended only through SSH tunneling.
- Ollama binds to `127.0.0.1` and is not exposed externally.

## Troubleshooting

- **Job starts, but the page keeps refreshing**. Model downloads and startup can take time. Check `ollama.log` and the Open WebUI logs in the job output directory.
- **Ollama dies immediately**. Verify the Ollama module, GPU driver compatibility (if using GPU), and that `OLLAMA_HOST` is not blocked.
- **Model not found in Open WebUI**. Ensure `OLLAMA_MODELS` points to the correct directory. Run `ollama list` in the job to confirm available models. If you are using system models, confirm permissions on the system directory.
- **Pull fails**. Confirm outbound connectivity to pull models, or use a site mirror. Check `ollama.log`.
- **Cannot SSH tunnel**. Confirm your site supports SSH to compute nodes. Adjust the jump host logic in `view.html.erb`.

## Developed by

- [Arshad Mehmood](https://rci.stonybrook.edu/HPC/team/arshad-mehmood)
- [David Carlson](https://rci.stonybrook.edu/HPC/team/david-carlson)
- [Feng Zhang](https://rci.stonybrook.edu/HPC/team/feng-zhang)

## Help and support

- Arshad Mehmood. arshad.mehmood@stonybrook.edu
- David Carlson. david.carlson@stonybrook.edu
- [SBU Research Computing & Informatics (RCI) team](https://rci.stonybrook.edu/our-team)
