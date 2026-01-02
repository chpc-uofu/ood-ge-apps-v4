# shutdown samba server cleanly so temp files can be removed
# Samba says "The safe way to terminate an smbd is to send it a SIGTERM (-15) signal and wait for it to die on its own"
echo "Shutting down samba server"
smbpid=$(ps aux | grep smbd | grep -v grep | awk '{print $2}')
kill -15 $smbpid
echo "Samba server should now be shut down"
#Clean up temporary directory on job exit.
rm -r ${JOB_TMP_DIR}

