# Clean up temporary directory on job exit.
rm -r ${JOB_TMP_DIR}

# shutdown samba server cleanly so temp files can be removed
# Samba says "The safe way to terminate an smbd is to send it a SIGTERM (-15) signal and wait for it to die on its own"
# echo "Shutting down samba server"
# smbpid=$(ps aux | grep smbd | grep -v grep | awk '{print $2}' | tr '\n' ' ')
# echo "smbpid is ${smbpid}"
# for p in ${smbpid}; do
#    kill -15 $p
#    echo "killing ${p}"
#    while [ -e /proc/$p ]; do sleep 1; done
#    echo "killed ${p}"
# done
# echo "Samba server should now be shut down"

