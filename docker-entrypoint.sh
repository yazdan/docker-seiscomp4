#!/usr/bin/env bash
set -e

# Copy local files
rsync -av $SEISCOMP4_CONFIG/ $INSTALL_DIR/
rsync -av $LOCAL_CONFIG/ /home/sysop/.seiscomp4/

# Give right to user sysop
chown -R sysop:sysop $INSTALL_DIR
chown -R sysop:sysop /home/sysop/.seiscomp4

# Execute init scripts
for f in $ENTRYPOINT_INIT/*; do
    # Check if $f is a regular file
    [ -f "$f" ] || continue
    echo "$0: running $f"; . "$f"
done

# Enable modules
for s in $(env | grep ^ENABLE_); do
    service_name=$(echo $s | cut -d '=' -f 1 | cut -d '_' -f 2 | tr '[A-Z]' '[a-z]')
    gosu sysop seiscomp enable $service_name
done

# Start seiscomp
case $1 in
    "")
        gosu sysop seiscomp start

        # Redirect logs
        for log_file in /home/sysop/.seiscomp4/log/*.log; do
            (tail -F $log_file | sed --unbuffered -e "s/^/[`basename $log_file`] /") &
        done

        tail -f /dev/null
    ;;
    install-deps|setup|shell|enable|disable|start|stop|restart|check|status|list|exec|update-config|alias|print|help)
        exec gosu sysop seiscomp "$@"
    ;;
    *)
        exec "$@"
esac
