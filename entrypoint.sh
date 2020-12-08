#!/bin/bash
# Docker entrypoint
#
# Author: gw0 [http://gw.tnode.com/] <gw.2016@tnode.com>
set -e

# initialize on first run
echo "Initializing..."
mkdir -p /var/log/dovecot /var/log/offlineimap

touch /var/log/dovecot/dovecot.log
chown root:users /var/log/dovecot/dovecot.log
chmod 664 /var/log/dovecot/dovecot.log

touch /var/log/offlineimap/offlineimap.log
chown root:users /var/log/offlineimap/offlineimap.log
chmod 664 /var/log/offlineimap/offlineimap.log

for USER in $(ls -1 /home); do
  echo "User '$USER':"
  if ! id -u "$USER" >/dev/null 2>&1; then
    # create user with default password
    useradd --groups=users --no-create-home --shell='/bin/true' "$USER"
    echo -e "$DEFAULT_PASSWD\n$DEFAULT_PASSWD\n" | passwd "$USER"
    chown -R "$USER:$USER" "/home/$USER"
    chmod 700 /home/$USER/{.maildir,.offlineimap} || true
  fi
done

# start services
echo "Starting services..."
/etc/init.d/dovecot start
/etc/init.d/cron start
chmod +x /usr/local/bin/burlproxy.py
nohup python3 /usr/local/bin/burlproxy.py &

exec "$@"
