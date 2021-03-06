#!/bin/bash
#
# Title:      PGBlitz (Reference Title File)
# Author(s):  Admin9705
# URL:        https://pgblitz.com - http://github.pgblitz.com
# GNU:        General Public License v3.0
################################################################################
# NOTES
# Variables come from what's being called from deploymove.sh under functions
## BWLIMIT 9 and Lower Prevents Google 750GB Google Upload Ban
################################################################################
if pidof -o %PPID -x "$0"; then
    exit 1
fi

touch /var/plexguide/logs/pgmove.log

echo "" >>/var/plexguide/logs/pgmove.log
echo "" >>/var/plexguide/logs/pgmove.log
echo "---Starting Move: $(date "+%Y-%m-%d %H:%M:%S")---" >>/var/plexguide/logs/pgmove.log
move_threshold=60

startscript() {
    while read p; do

        useragent="$(cat /var/plexguide/uagent)"
        bwlimit="$(cat /var/plexguide/move.bw)"
        vfs_dcs="$(cat /var/plexguide/vfs_dcs)"
        let "cyclecount++"

        if [[ $cyclecount -gt 4294967295 ]]; then
            cyclecount=0
        fi

        echo "" >>/var/plexguide/logs/pgmove.log
        echo "---Begin cycle $cyclecount: $(date "+%Y-%m-%d %H:%M:%S")---" >>/var/plexguide/logs/pgmove.log
        echo "Checking for files to upload..." >>/var/plexguide/logs/pgmove.log

        rsync "{{hdpath}}/downloads/" "{{hdpath}}/move/" \
            -aq --remove-source-files --link-dest="{{hdpath}}/downloads/" \
            --exclude="**_HIDDEN~" --exclude=".unionfs/**" \
            --exclude="**partial~" --exclude=".unionfs-fuse/**" \
            --exclude=".fuse_hidden**" --exclude="**.grab/**" \
            --exclude="**sabnzbd**" --exclude="**nzbget**" \
            --exclude="**qbittorrent**" --exclude="**rutorrent**" \
            --exclude="**deluge**" --exclude="**transmission**" \
            --exclude="**jdownloader**" --exclude="**makemkv**" \
            --exclude="**handbrake**" --exclude="**bazarr**" \
            --exclude="**ignore**" --exclude="**inProgress**"

        move_size=$(du -s "{{hdpath}}/move" | cut -f1 | bc -l | rev | cut -c 2- | rev)
        if [ "$move_size" -gt "$move_threshold" ]; then

            rclone move "{{hdpath}}/move/" "{{type}}:/" \
                --config=/opt/appdata/plexguide/rclone.conf \
                --log-file=/var/plexguide/logs/pgmove.log \
                --log-level=INFO --stats=5s --stats-file-name-length=0 \
                --max-size=300G \
                --tpslimit=10 \
                --checkers=16 \
                --no-traverse \
                --fast-list \
                --bwlimit="$bwlimit" \
                --drive-chunk-size="$vfs_dcs" \
                --user-agent="$useragent" \
                --exclude="**_HIDDEN~" --exclude=".unionfs/**" \
                --exclude="**partial~" --exclude=".unionfs-fuse/**" \
                --exclude=".fuse_hidden**" --exclude="**.grab/**" \
                --exclude="**sabnzbd**" --exclude="**nzbget**" \
                --exclude="**qbittorrent**" --exclude="**rutorrent**" \
                --exclude="**deluge**" --exclude="**transmission**" \
                --exclude="**jdownloader**" --exclude="**makemkv**" \
                --exclude="**handbrake**" --exclude="**bazarr**" \
                --exclude="**ignore**" --exclude="**inProgress**"

        else
            echo "No files in {{hdpath}}/move to upload." >>/var/plexguide/logs/pgmove.log
        fi
        sleep 30

        # Remove empty directories
        find "{{hdpath}}/move" -mindepth 2 -type d -empty -delete
        #DO NOT decrease DEPTH on this, leave it at 3. Leave this alone!
        find "{{hdpath}}/downloads" -mindepth 3 -empty -delete
        # Prevents category folders underneath the downloaders from being deleted, while removing empties from sonarr moving the files.
        # This was done to address lazylibrarian having an issue if the ebooks/abooks category underneath the downloader is missing.
        # If this causes issues, remove the names as needed, but keep ebooks and abooks being excluded.
        find "{{hdpath}}/downloads" -mindepth 2 -type d \( ! -name ebooks ! -name abooks ! -name tv** ! -name **movies** ! -name music** ! -name audio** ! -name anime** ! -name software ! -name xxx \) -empty -delete

        echo "---Completed cycle $cyclecount: $(date "+%Y-%m-%d %H:%M:%S")---" >>/var/plexguide/logs/pgmove.log

        echo "$(tail -n 200 /var/plexguide/logs/pgmove.log)" >/var/plexguide/logs/pgmove.log

    done
}

# keeps the function in a loop
cheeseballs=0
while [[ "$cheeseballs" == "0" ]]; do startscript; done
