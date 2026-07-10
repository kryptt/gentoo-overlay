FROM gentoo/stage3:latest

# Sync the main Gentoo repository. Use emerge-webrsync (signed snapshot
# tarball) instead of live rsync: rsync mirrors frequently drop the
# connection mid-transfer inside containers, failing the build (exit 1).
RUN emerge-webrsync

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

# Configure repos in repos.conf. pkgdev/pkgcheck are pkgcore-based and read
# ONLY /etc/portage/repos.conf/ — they do NOT fall back to portage's
# /usr/share/portage/config/repos.conf default. So the 'gentoo' master must be
# declared explicitly here, or pkgdev fails with "default repo 'gentoo' is
# undefined or invalid".
RUN mkdir -p /etc/portage/repos.conf && \
    printf '[DEFAULT]\nmain-repo = gentoo\n\n[gentoo]\nlocation = /var/db/repos/gentoo\nauto-sync = no\n' \
    > /etc/portage/repos.conf/gentoo.conf && \
    printf '[rhansen-overlay]\nlocation = /var/db/repos/rhansen-overlay\nmasters = gentoo\nauto-sync = no\n' \
    > /etc/portage/repos.conf/rhansen-overlay.conf

# Accept all keywords for testing (~arch packages)
RUN echo 'ACCEPT_KEYWORDS="~amd64"' >> /etc/portage/make.conf

# Set a reasonable MAKEOPTS. Evaluate nproc at build time (double quotes) —
# single quotes wrote a literal $(nproc) that portage chokes on ("bad
# substitution" on every emerge/portageq call).
RUN echo "MAKEOPTS=\"-j$(nproc)\"" >> /etc/portage/make.conf

# Create a non-root user with UID 1000, in wheel group for su access
RUN useradd -m -u 1000 -s /bin/bash -G wheel developer && \
    (echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers || true) && \
    passwd -d developer

# Install Claude Code for the developer user
RUN su - developer -c 'curl -fsSL https://claude.ai/install.sh | sh'
