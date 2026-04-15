# Shared render-time operator config for the OOD templates that generate the
# CryoSPARC launch and supervision scripts.
module CryoSPARCSiteConfig
  # These defaults preserve the app's current behavior when no deployment
  # environment overrides are provided.
  DEFAULTS = {
    "frp_token_file_path" => "/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/frp/.frp_token",
    "frps_addr" => "155.101.26.122",
    "frps_port" => "7000",
    "base_domain" => "cryosparc.ondemand-staging.chpc.utah.edu",
    "user_access_port" => "8443",
    "module_apptainer" => "apptainer/1.4.1",
    "module_frp" => "frp/0.68.1",
    # Version-keyed deployment artifacts used by the main batch script.
    "artifacts" => {
      "v5.0.4-beta" => {
        "image_path" => "/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/build/v5.0.4.sif",
        "init_tarball_path" => "/uufs/chpc.utah.edu/common/home/u6047586/ondemand/ood-ge-apps-v4/cryosparc_app_subdomain/build/cryosparc_master_run_init_files-v5.0.4.tar.gz"
      },
      "v4.7.1-cuda12+250814" => {
        "image_path" => "/uufs/chpc.utah.edu/common/home/u6047586/dor-hprc-ood-apps/cryosparc/INSTALL/cryosparc-v4.7.1-cuda12+250814.sif",
        "init_tarball_path" => "/uufs/chpc.utah.edu/common/home/u6047586/dor-hprc-ood-apps/cryosparc/bk_cryosparc_master_run_init_files-v4.7.1.tar.gz"
      }
    }
  }.freeze

  # Resolve deployment environment overrides at ERB render time and return a
  # plain hash for templates. A custom env hash can be passed for testing.
  def self.load(env = ENV)
    {
      "frp_token_file_path" => env.fetch("CRYOSPARC_FRP_TOKEN_FILE_PATH", DEFAULTS["frp_token_file_path"]),
      "frps_addr" => env.fetch("CRYOSPARC_FRPS_ADDR", DEFAULTS["frps_addr"]),
      "frps_port" => env.fetch("CRYOSPARC_FRPS_PORT", DEFAULTS["frps_port"]),
      "base_domain" => env.fetch("CRYOSPARC_BASE_DOMAIN", DEFAULTS["base_domain"]),
      "user_access_port" => env.fetch("CRYOSPARC_USER_ACCESS_PORT", DEFAULTS["user_access_port"]),
      "module_apptainer" => env.fetch("CRYOSPARC_MODULE_APPTAINER", DEFAULTS["module_apptainer"]),
      "module_frp" => env.fetch("CRYOSPARC_MODULE_FRP", DEFAULTS["module_frp"]),
      "artifacts" => {
        "v5.0.4-beta" => {
          "image_path" => env.fetch("CRYOSPARC_V5_IMAGE_PATH", DEFAULTS["artifacts"]["v5.0.4-beta"]["image_path"]),
          "init_tarball_path" => env.fetch("CRYOSPARC_V5_INIT_TARBALL_PATH", DEFAULTS["artifacts"]["v5.0.4-beta"]["init_tarball_path"])
        },
        "v4.7.1-cuda12+250814" => {
          "image_path" => env.fetch("CRYOSPARC_V4_IMAGE_PATH", DEFAULTS["artifacts"]["v4.7.1-cuda12+250814"]["image_path"]),
          "init_tarball_path" => env.fetch("CRYOSPARC_V4_INIT_TARBALL_PATH", DEFAULTS["artifacts"]["v4.7.1-cuda12+250814"]["init_tarball_path"])
        }
      }
    }
  end
end
