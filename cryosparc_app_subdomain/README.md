# CryoSPARC Server (subdomain)

Open OnDemand batch-connect app for launching a CryoSPARC master inside an Apptainer instance and exposing it through FRP with a generated subdomain URL.

## Dependencies and hard-coded assumptions

- Operator-configurable env vars with current defaults:
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
- Shared operator config is resolved at ERB render time in `site_config.rb`.
- Remaining hard-coded runtime assumptions not moved in this pass:
  - admin email format inside the container: `${USER}@cryo.edu`
  - custom supervisor config bind mount: `${PWD}/supervisord.conf_daemon` to `/cryosparc_master/supervisord.conf`
  - Slurm job email lookup helper in `submit.yml.erb`: `/uufs/chpc.utah.edu/sys/bin/CHPCEmailLookup.sh`
  - container bind assumptions include `/uufs`, `/scratch`, and `$TMPDIR`

## Files

- `manifest.yml`: app metadata shown in Open OnDemand.
- `form.yml.erb`: launch form fields, including CryoSPARC version, database root, license ID, cluster, and scheduler options.
- `submit.yml.erb`: Slurm submission settings and job email configuration.
- `template/before.sh.erb`: pre-launch setup. Builds the subdomain/URL, writes `frpc.toml`, and copies the FRP token into the staged session directory.
- `template/script.sh.erb`: main batch script. Starts the Apptainer instance, launches CryoSPARC, starts `frpc`, and supervises FRP plus CryoSPARC health.
- `template/cryosparc_container_startup.sh`: in-container CryoSPARC initialization and worker connection logic.
- `template/after.sh.erb`: post-session cleanup hook.
- `frp/`: FRP binaries, sample config, and notes.
- `build/`: Apptainer images, definitions, CryoSPARC tarballs, and build notes/logs.

## Runtime Flow

1. `before.sh.erb` prevents duplicate queued/running CryoSPARC subdomain sessions for the same user.
2. It finds a CryoSPARC port, derives a DNS-safe subdomain, and exports `EXTERNAL_URL`.
3. It writes `frpc.toml` and stages `.frp_token` into the session directory.
4. `script.sh.erb` loads `apptainer` and `frp`, starts the CryoSPARC Apptainer instance, and runs `cryosparc_container_startup.sh` inside it.
5. `script.sh.erb` starts `frpc` in the background, removes the staged token once FRP reports startup success, then supervises session lifetime.
6. Session supervision ends immediately if `frpc` exits, or after 3 consecutive failed `cryosparcm status` checks for required services.

## Important Configuration

- FRP server settings live near the top of `template/before.sh.erb`:
  - `FRPS_ADDR`
  - `FRPS_PORT`
  - `BASE_DOMAIN`
  - `USER_ACCESS_PORT`
- The FRP token source path is operator-configurable through `CRYOSPARC_FRP_TOKEN_FILE_PATH`.
  - If unset, it falls back to `frp/.frp_token` in this app directory.
- When `USER_ACCESS_PORT` is `443`, `EXTERNAL_URL` omits the port.
- Subdomains include:
  - sanitized username
  - first 4 chars of OOD session id
  - first 2 chars of cluster name
  - Slurm job id
  - random suffix

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

`app_api_dev` may be `STOPPED Not started` and is treated as acceptable.

## Notes for Maintainers

- This app currently supports:
  - `v4.7.1-cuda12+250814`
  - `v5.0.4-beta`
- CryoSPARC user data is stored under:
  - `${cryosparc_database_root}/.cryosparc-${SELECTED_CRYO_VERSION}`
- The batch script still uses Slurm email notifications from `submit.yml.erb`.
- Avoid running app debugging or heavy work on login nodes outside normal OOD job flow.
