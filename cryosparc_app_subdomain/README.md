# CryoSPARC Server in Open OnDemand

This Open OnDemand (OOD) app launches a per-user CryoSPARC instance on the HPC cluster. Both the CryoSPARC Master and Worker run within the same Slurm job on a GPU compute node.

Backed by a [custom Reverse Proxy service](https://github.com/chpc-uofu/ood_cryosparc_frps), the app lets you access the launched CryoSPARC instance directly from your local web browser without needing a remote desktop ("browser in browser") or an SSH tunnel setup.

## User Notes

### Currently Supported CryoSPARC Versions

- v4.7.1-cuda12+251124
- v5.0.4-beta

### Requirements

- A CryoSPARC License ID is required. You can request an individual academic license ID at `cryosparc.com/download`.
- Each user can have only ONE (1) active CryoSPARC instance at any time.

### Database Storage

- The CryoSPARC database is stored under `Database Root` of your choice. Each app version will have a dedicated sub-folder under it. You are NOT supposed to make any manual changes to folders and files under `Database Root`.
- When you restart an instance of the same version later, the previously stored database will be reused.
- CryoSPARC databases may grow quickly, so choose a location with enough available space.
- If the Database Root becomes full and writes are blocked, the database may become corrupted.
- Reminder: the free-tier `HOME` space is capped at `50G/user`, which is only suitable for hosting a CryoSPARC database for testing purposes unless your PI group has purchased extra HOME space.

### Login

- Access to the launched CryoSPARC instance is protected by both CHPC/UofUtah login and CryoSPARC's native login.
- After signing in with your uNID credentials, you will be directed to the CryoSPARC native login page.
- Your CryoSPARC username is fixed as `<uNID>@cryo.edu`.
- You can set a password in the OOD UI, or use the default password, which is the first 4 characters of the License ID.
### Walltime Reminder

- You will receive Slurm email notifications when your instance reaches 80% and 90% of its walltime.
- Save your work and manually shut down the instance before walltime expires to prevent potential database corruption.

# Dev/Deploy Notes

Open OnDemand batch-connect app for launching a CryoSPARC (master + worker) inside an Apptainer instance and exposing it through FRP with a generated subdomain URL.

The dedicated [Reverse Proxy](https://github.com/chpc-uofu/ood_cryosparc_frps), deployed outside the OOD server, serves as the user entry point to the launched CryoSPARC instance running on the compute node.

## Configuration Model

This app uses a two-layer configuration model:

1. `site_config.yml` (required) provides site default values.
2. `CRYOSPARC_*` environment variables override those defaults at render time.

## Site Defaults (`site_config.yml`)

Top-level keys:

- `frp_token_file_path`: Path to the FRP token file.
- `frps_addr`: FRP server hostname or IP address (internal network).
- `frps_port`: FRP server port (internal network).
- `base_domain`: Base domain used to build per-session subdomain URLs.
- `user_access_port`: External user-facing HTTPS port. Use `443` for the default HTTPS URL without an custom port.
- `module_apptainer`: Module name for the Apptainer runtime.
- `module_frp`: Module name for the FRP client.
- `artifacts`: Version-specific CryoSPARC deployment artifacts.

Artifact keys:

- `artifacts.v5.0.4-beta.image_path`: CryoSPARC v5 image path.
- `artifacts.v5.0.4-beta.init_tarball_path`: CryoSPARC v5 first-run init tarball path.
- `artifacts.v4.7.1-cuda12+251124.image_path`: CryoSPARC v4 image path.
- `artifacts.v4.7.1-cuda12+251124.init_tarball_path`: CryoSPARC v4 first-run init tarball path.

## Supported Environment Overrides (optional)

- `CRYOSPARC_FRP_TOKEN_FILE_PATH` --> `frp_token_file_path`
- `CRYOSPARC_FRPS_ADDR` --> `frps_addr`
- `CRYOSPARC_FRPS_PORT` --> `frps_port`
- `CRYOSPARC_BASE_DOMAIN` --> `base_domain`
- `CRYOSPARC_USER_ACCESS_PORT` --> `user_access_port`
- `CRYOSPARC_MODULE_APPTAINER` --> `module_apptainer`
- `CRYOSPARC_MODULE_FRP` --> `module_frp`
- `CRYOSPARC_V5_IMAGE_PATH` --> `artifacts.v5.0.4-beta.image_path`
- `CRYOSPARC_V5_INIT_TARBALL_PATH` --> `artifacts.v5.0.4-beta.init_tarball_path`
- `CRYOSPARC_V4_IMAGE_PATH` --> legacy `artifacts.v4.7.1-cuda12+250814.image_path`
- `CRYOSPARC_V4_INIT_TARBALL_PATH` --> legacy `artifacts.v4.7.1-cuda12+250814.init_tarball_path`
- `CRYOSPARC_V4_251124_IMAGE_PATH` --> `artifacts.v4.7.1-cuda12+251124.image_path`
- `CRYOSPARC_V4_251124_INIT_TARBALL_PATH` --> `artifacts.v4.7.1-cuda12+251124.init_tarball_path`

## Files

- `manifest.yml`: app metadata shown in Open OnDemand. It still uses the app name `Cryosparc Server (subdomain)`.
- `form.yml.erb`: launch form + hidden `cfg_*` defaults loaded from `site_config.yml`.
- `submit.yml.erb`: Slurm submission settings and job email configuration.
- `site_config.yml`: site default configuration values.
- `template/before.sh.erb`: pre-launch setup, FRP config generation, staged token setup.
- `template/script.sh.erb`: main batch script, Apptainer startup, CryoSPARC launch, FRP supervision, and health checks.
- `template/cryosparc_container_startup.sh`: in-container CryoSPARC initialization and worker connection logic.
- `template/after.sh.erb`: post-session cleanup hook.

## Runtime Flow

1. `form.yml.erb` loads defaults from `site_config.yml`.
2. `before.sh.erb` resolves FRP and URL settings from `CRYOSPARC_*` env vars with `context.cfg_*` fallback.
3. `before.sh.erb` stages `.frp_token` into the session directory.
4. `script.sh.erb` resolves module and artifact paths from `CRYOSPARC_*` env vars with `context.cfg_*` fallback.
5. `script.sh.erb` starts Apptainer + CryoSPARC and launches FRP.
6. The session remains alive while FRP is running and health checks pass.

## Notes

- Hardcoded runtime assumptions still present:
  - admin email format `${USER}@cryo.edu`
  - bind mounts include `/uufs`, `/scratch`, and `$TMPDIR`
