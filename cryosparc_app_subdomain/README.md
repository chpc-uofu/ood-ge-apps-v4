# CryoSPARC Server (subdomain)

Open OnDemand batch-connect app for launching a CryoSPARC master inside an Apptainer instance and exposing it through FRP with a generated subdomain URL.

## Current Configuration Behavior

- Shared operator config is loaded at ERB render time from `site_config.rb`.
- `template/before.sh.erb` and `template/script.sh.erb` currently try `site_config` candidates in this order:
  - `File.expand_path("./site_config", Dir.pwd)`
  - `File.expand_path("./cryosparc_app_subdomain/site_config", Dir.pwd)`
  - `/var/www/ood/apps/dev/u6047586/gateway/cryosparc_app_subdomain/site_config`
- The first candidate with an existing `*.rb` file wins.
- Current dev/sandbox behavior works because the third candidate is a hardcoded dev-only fallback path.
- If no candidate exists, the templates raise `LoadError` listing the attempted paths.

## Operator Defaults in `site_config.rb`

- `CRYOSPARC_FRP_TOKEN_FILE_PATH`
  - default: `/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/frp/.frp_token`
- `CRYOSPARC_FRPS_ADDR`
  - default: `155.101.26.122`
- `CRYOSPARC_FRPS_PORT`
  - default: `7000`
- `CRYOSPARC_BASE_DOMAIN`
  - default: `cryosparc.ondemand-staging.chpc.utah.edu`
- `CRYOSPARC_USER_ACCESS_PORT`
  - default: `8443`
- `CRYOSPARC_MODULE_APPTAINER`
  - default: `apptainer/1.4.1`
- `CRYOSPARC_MODULE_FRP`
  - default: `frp/0.68.1`
- `CRYOSPARC_V5_IMAGE_PATH`
  - default: `/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/build/v5.0.4.sif`
- `CRYOSPARC_V5_INIT_TARBALL_PATH`
  - default: `/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/build/cryosparc_master_run_init_files-v5.0.4.tar.gz`
- `CRYOSPARC_V4_IMAGE_PATH`
  - default: `/uufs/chpc.utah.edu/common/home/u6047586/dor-hprc-ood-apps/cryosparc/INSTALL/cryosparc-v4.7.1-cuda12+250814.sif`
- `CRYOSPARC_V4_INIT_TARBALL_PATH`
  - default: `/uufs/chpc.utah.edu/common/home/u6047586/dor-hprc-ood-apps/cryosparc/bk_cryosparc_master_run_init_files-v4.7.1.tar.gz`

## Hardcoded and Host-Specific Assumptions

- Temporary dev-only fallback for `site_config.rb`:
  - `/var/www/ood/apps/dev/u6047586/gateway/cryosparc_app_subdomain/site_config`
- Still-hardcoded runtime assumptions:
  - admin email inside the container: `${USER}@cryo.edu`
  - bind mounts include `/uufs`, `/scratch`, and `$TMPDIR`
  - custom supervisor config bind mount: `${PWD}/supervisord.conf_daemon` to `/cryosparc_master/supervisord.conf`
  - Slurm email lookup helper in `submit.yml.erb`: `/uufs/chpc.utah.edu/sys/bin/CHPCEmailLookup.sh`
  - shared form snippet root in `form.yml.erb`: `/var/www/ood/apps/templates/`

## Files

- `manifest.yml`: app metadata shown in Open OnDemand.
- `form.yml.erb`: launch form fields, including CryoSPARC version, database root, license ID, cluster, and scheduler options.
- `submit.yml.erb`: Slurm submission settings and job email configuration.
- `site_config.rb`: shared render-time operator config and env-var overrides.
- `template/before.sh.erb`: pre-launch setup, FRP config generation, staged token setup, and render-time diagnostics.
- `template/script.sh.erb`: main batch script, Apptainer startup, CryoSPARC launch, FRP supervision, and health checks.
- `template/cryosparc_container_startup.sh`: in-container CryoSPARC initialization and worker connection logic.
- `template/after.sh.erb`: post-session cleanup hook.
- `frp/`: FRP binaries, sample config, and notes.
- `build/`: Apptainer images, definitions, CryoSPARC tarballs, build notes, and logs.
- `.gitignore`: app-local ignore rules for generated build artifacts and local FRP binaries.

## Runtime Flow

1. `before.sh.erb` loads `site_config.rb` from the first matching `site_config_candidates` entry.
2. It blocks duplicate queued/running CryoSPARC subdomain sessions for the same user.
3. It finds an available CryoSPARC port and exports `CRYOSPARC_PORT`.
4. It derives a DNS-safe subdomain using:
   - sanitized username
   - first 4 characters of the OOD session id
   - first 2 characters of the cluster name
   - Slurm job id
   - random suffix
5. It sets `EXTERNAL_URL`.
   - When `USER_ACCESS_PORT` is `443`, the URL omits the port.
   - Otherwise the URL includes `:${USER_ACCESS_PORT}`.
6. It writes `frpc.toml` in the staged working directory.
7. It writes render-time diagnostics to `session.staged_root/render_logs`, including:
   - selected `site_config_path`
   - attempted `site_config_candidates`
8. It stages `.frp_token` into the session directory from `site_cfg["frp_token_file_path"]`.
9. `script.sh.erb` loads `apptainer` and `frp` module names from `site_config.rb`.
10. `script.sh.erb` chooses the CryoSPARC image and init tarball from `site_cfg["artifacts"]` based on the selected version.
11. On first launch, it creates the CryoSPARC user directories and extracts the init tarball.
12. It starts the Apptainer instance, runs `cryosparc_container_startup.sh`, and launches `frpc`.
13. After FRP reports startup success, it removes the staged one-time token file.
14. The session stays alive while FRP is running and CryoSPARC health checks pass.
15. The session ends if `frpc` exits, or after 3 consecutive failed `cryosparcm status` checks for required services.

## CryoSPARC Health Monitoring

`template/script.sh.erb` checks CryoSPARC health from the host with:

```bash
apptainer exec "instance://${cryo_apptainer_instance}" cryosparcm status
```

The current health check requires these services to report `RUNNING`:

- `app`
- `app_api`
- `command_core`
- `command_rtp`
- `command_vis`
- `database`

## Notes for Maintainers

- This app currently supports:
  - `v4.7.1-cuda12+250814`
  - `v5.0.4-beta`
- CryoSPARC user data is stored under:
  - `${cryosparc_database_root}/.cryosparc-${SELECTED_CRYO_VERSION}`
- The README currently documents the app as it works in dev/sandbox, including the temporary hardcoded `site_config` fallback.
- `render_logs` output is temporary diagnostic behavior and should be cleaned up once path resolution is finalized.
