# CryoSPARC Server (subdomain)

Open OnDemand batch-connect app for launching a CryoSPARC master inside an Apptainer instance and exposing it through FRP with a generated subdomain URL.

## Configuration Model

This app now uses a two-layer configuration model:

1. `site_config.yml` (required) provides site default values.
2. `CRYOSPARC_*` environment variables override those defaults at render time.

`form.yml.erb` loads `site_config.yml` using a relative path and injects defaults into hidden `cfg_*` context attributes. Runtime templates use ENV-first resolution with `context.cfg_*` fallback.

## Site Defaults (`site_config.yml`)

Top-level keys:

- `frp_token_file_path`
- `frps_addr`
- `frps_port`
- `base_domain`
- `user_access_port`
- `module_apptainer`
- `module_frp`
- `artifacts`

Artifact keys:

- `artifacts.v5.0.4-beta.image_path`
- `artifacts.v5.0.4-beta.init_tarball_path`
- `artifacts.v4.7.1-cuda12+250814.image_path`
- `artifacts.v4.7.1-cuda12+250814.init_tarball_path`

## Supported Environment Overrides

- `CRYOSPARC_FRP_TOKEN_FILE_PATH`
- `CRYOSPARC_FRPS_ADDR`
- `CRYOSPARC_FRPS_PORT`
- `CRYOSPARC_BASE_DOMAIN`
- `CRYOSPARC_USER_ACCESS_PORT`
- `CRYOSPARC_MODULE_APPTAINER`
- `CRYOSPARC_MODULE_FRP`
- `CRYOSPARC_V5_IMAGE_PATH`
- `CRYOSPARC_V5_INIT_TARBALL_PATH`
- `CRYOSPARC_V4_IMAGE_PATH`
- `CRYOSPARC_V4_INIT_TARBALL_PATH`

## Files

- `manifest.yml`: app metadata shown in Open OnDemand.
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

- Supported CryoSPARC versions:
  - `v4.7.1-cuda12+250814`
  - `v5.0.4-beta`
- CryoSPARC user data root:
  - `${cryosparc_database_root}/.cryosparc-${SELECTED_CRYO_VERSION}`
- Hardcoded runtime assumptions still present:
  - admin email format `${USER}@cryo.edu`
  - bind mounts include `/uufs`, `/scratch`, and `$TMPDIR`
