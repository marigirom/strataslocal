FROM rockylinux:9

LABEL maintainer="strataslocal"
LABEL description="data-node: Rocky Linux 9 with sshd and MariaDB"

# Install required packages
# hadolint ignore=DL3041
RUN dnf -y update && \
    dnf -y install \
        openssh-server \
        openssh-clients \
        sudo \
        shadow-utils \
        cronie \
        acl \
        procps-ng \
        bind-utils \
        traceroute \
        bind \
        tar \
        gzip \
        util-linux \
        policycoreutils \
        bash \
        mariadb-server \
        && \
    dnf clean all

# Install bats-core from submodule (copied in at build time)
# Build context is linux/ so submodule is at tests/bats-core
COPY tests/bats-core/ /tmp/bats-core/
RUN bash /tmp/bats-core/install.sh /usr/local && rm -rf /tmp/bats-core

# Copy hardened sshd config
COPY dockerfiles/data-node/sshd_config /etc/ssh/sshd_config
RUN chmod 600 /etc/ssh/sshd_config

# Create devops user (UID 2000) with sudo access and SSH key
RUN useradd -m -u 2000 -s /bin/bash -c "DevOps User" devops && \
    echo "devops ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devops && \
    chmod 440 /etc/sudoers.d/devops

RUN mkdir -p /home/devops/.ssh && \
    chmod 700 /home/devops/.ssh && \
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUh77uQe1onGm60r7CGztf89NOsnfP+Yt4dquWAhjpm romarsmarigi@gmail.com" \
        > /home/devops/.ssh/authorized_keys && \
    chmod 600 /home/devops/.ssh/authorized_keys && \
    chown -R devops:devops /home/devops/.ssh

# Explicit MariaDB datadir (Phase 2 will expand this)
RUN mkdir -p /var/lib/mysql && chown mysql:mysql /var/lib/mysql

# Entrypoint: init MariaDB, start both services
COPY dockerfiles/data-node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 3306

CMD ["/entrypoint.sh"]
