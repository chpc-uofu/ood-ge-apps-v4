# v5.0.4
set -x 

VERSION="v5.0.4"
echo "LICENSE_ID=$LICENSE_ID"
#curl -L https://get.cryosparc.com/download/master-latest/$LICENSE_ID -o /mnt/cryosparc_master.tar.gz
#curl -L https://get.cryosparc.com/download/worker-latest/$LICENSE_ID -o /mnt/cryosparc_worker.tar.gz


export USER=admin
export CRYOSPARC_FORCE_USER=true
export CRYOSPARC_FORCE_HOSTNAME=true

echo "extracting install packages"
tar xzf /mnt/cryosparc_master.tar.gz -C /
tar xzf /mnt/cryosparc_worker.tar.gz -C /
echo "DONE: extracting install packages"

# comment out the ping localhost line
sed -i '/ping -c/ { N; N; N; s/^/#/; s/\n/&#/g }' /cryosparc_master/install.sh

cd /cryosparc_master && ./install.sh --standalone --yes  --hostname localhost  --license $LICENSE_ID   --worker_path /cryosparc_worker --port 61000  --initial_email "admin@cryo.edu"   --initial_password "admin"   --initial_username "admin"   --initial_firstname "admin"   --initial_lastname "admin"

# add a new user (optional)
# cryosparcm createuser --email "user@organization" --password "init-password" --username "myuser" --firstname "John" --lastname "Doe"
sleep 60

#cp /mnt/update_v4.7.1-cuda12/*.tar.gz /cryosparc_master 
#/cryosparc_master/bin/cryosparcm update --skip-download --version=v4.7.1-cuda12
#/cryosparc_master/bin/cryosparcm update --version=v4.7.1-cuda12

/cryosparc_master/bin/cryosparcm patch --yes
/cryosparc_master/bin/cryosparcm stop

# create a script to remove previous compute node host
cat > /cryosparc_master/bin/remove_hosts.sh <<EOTF
#!/usr/bin/env bash

/cryosparc_master/bin/cryosparcm cli 'get_scheduler_targets()'  | /usr/bin/python3 -c "import sys, ast, json; print( json.dumps(ast.literal_eval(sys.stdin.readline())) )" | /usr/bin/jq '.[].name' | sed 's:"::g' | xargs -I \{\} /cryosparc_master/bin/cryosparcm cli 'remove_scheduler_target_node("'{}'")'

EOTF
chmod +x /cryosparc_master/bin/remove_hosts.sh

# edit config.sh
sed -i 's,export CRYOSPARC_LICENSE_ID=.\+,export CRYOSPARC_LICENSE_ID=$(cat /cryosparc_license/license_id),' /cryosparc_master/config.sh
sed -i 's,export CRYOSPARC_LICENSE_ID=.\+,export CRYOSPARC_LICENSE_ID=$(cat /cryosparc_license/license_id),' /cryosparc_worker/config.sh
sed -i 's,export CRYOSPARC_BASE_PORT=.\+,,' /cryosparc_master/config.sh
sed -i 's,export CRYOSPARC_MASTER_HOSTNAME=.\+,,' /cryosparc_master/config.sh
sed -i 's,source config.sh,source /cryosparc_master/config.sh,' /cryosparc_master/bin/cryosparcm

echo "export CRYOSPARC_HOSTNAME_CHECK=localhost" >> /cryosparc_worker/config.sh
echo "export CRYOSPARC_MASTER_HOSTNAME=localhost" >> /cryosparc_worker/config.sh
echo "export CRYOSPARC_FORCE_USER=true" >> /cryosparc_worker/config.sh
echo "export CRYOSPARC_FORCE_HOSTNAME=true" >> /cryosparc_worker/config.sh

echo "export CRYOSPARC_HOSTNAME_CHECK=localhost" >> /cryosparc_master/config.sh
echo "export CRYOSPARC_MASTER_HOSTNAME=localhost" >> /cryosparc_master/config.sh
echo "export CRYOSPARC_FORCE_USER=true" >> /cryosparc_master/config.sh
echo "export CRYOSPARC_FORCE_HOSTNAME=true" >> /cryosparc_master/config.sh
echo "export no_proxy=localhost,127.0.0.0/8" >> /cryosparc_master/config.sh

mv /cryosparc_master/config.sh /cryosparc_master/run/
ln -s /cryosparc_master/run/config.sh /cryosparc_master/config.sh

#tar czf /cryosparc_master_run_init_files-v4.7.1.tar.gz /cryosparc_master/run && rm -rf /cryosparc_master/run/
tar czf /cryosparc_master_run_init_files-$VERSION.tar.gz /cryosparc_master/run
cp /cryosparc_master_run_init_files-$VERSION.tar.gz /mnt
echo "Done"