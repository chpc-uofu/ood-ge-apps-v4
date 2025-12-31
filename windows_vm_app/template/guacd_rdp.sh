echo "GUACD_RDP.SH:  Loading modules for guac..."
#Create environment necessary for loading the guac container
module load apptainer/1.4.1
module load nodejs/22.4.0

GUAC_DIR="/uufs/chpc.utah.edu/sys/installdir/r8/apache_guacamole"
export API_SESSION_TIMEOUT=1200
export SESSION_TIMEOUT=1200
echo "GUACD_RDP.SH:  launching guacd:..."
apptainer run ${GUAC_DIR}/guacd_latest.sif &
# Load in a while loop so if the container is killed, another one will start up
#( while true; do apptainer run ${GUAC_DIR}/guacd_latest.sif; sleep 1; done ) &
# Load in a while loop so if 7lbd_server.js is killed, another one will start up
echo "GUACD_RDP.SH:  Starting Guacd RDP Connector..."
node ${GUAC_DIR}/guacd_connector.js guacd_rdp.json >> guacd_log &
#( while true; do node ${GUAC_DIR}/guacd_connector.js guacd_rdp.json >> guacd_log; sleep 1; done ) & 

