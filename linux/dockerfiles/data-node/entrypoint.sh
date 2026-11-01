#!/bin/bash
set -euo pipefail

# Generate host keys if they don't exist (first boot)
ssh-keygen -A

# Initialise MariaDB data directory if empty
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "[entrypoint] Initialising MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB in background
mysqld_safe --datadir=/var/lib/mysql &

# Wait for MariaDB to be ready
for _i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        echo "[entrypoint] MariaDB is ready."
        break
    fi
    sleep 1
done

# Start sshd in foreground
exec /usr/sbin/sshd -D
