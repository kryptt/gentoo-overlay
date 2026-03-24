FROM gentoo/stage3:latest

# Sync the main Gentoo repository
RUN emerge --sync

# Install essential ebuild development and QA tools
RUN emerge -v --noreplace \
    dev-util/pkgcheck \
    dev-util/pkgdev \
    app-portage/gentoolkit \
    dev-vcs/git \
    net-misc/curl \
    net-misc/openssh \
    app-misc/jq \
    app-editors/vim \
    app-admin/sudo

# Set up the overlay directory
RUN mkdir -p /var/db/repos/rhansen-overlay

# Configure the overlay in repos.conf
RUN mkdir -p /etc/portage/repos.conf && \
    printf '[rhansen-overlay]\nlocation = /var/db/repos/rhansen-overlay\nmasters = gentoo\nauto-sync = no\n' \
    > /etc/portage/repos.conf/rhansen-overlay.conf

# Accept all keywords for testing (~arch packages)
RUN echo 'ACCEPT_KEYWORDS="~amd64"' >> /etc/portage/make.conf

# Set a reasonable MAKEOPTS
RUN echo 'MAKEOPTS="-j$(nproc)"' >> /etc/portage/make.conf

# Create a non-root user with UID 1000, in wheel group for su access
RUN useradd -m -u 1000 -s /bin/bash -G wheel developer && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel && \
    passwd -d developer

# Install Claude Code for the developer user
RUN su - developer -c 'curl -fsSL https://claude.ai/install.sh | sh'
