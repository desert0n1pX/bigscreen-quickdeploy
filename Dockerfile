FROM archlinux:latest

WORKDIR /build

RUN mkdir -p /opt/bigscreen-quickdeploy/mediabox

COPY deploy.sh /opt/bigscreen-quickdeploy/

COPY mediabox /opt/bigscreen-quickdeploy/mediabox

RUN pacman -Syy --noconfirm core/diffutils core/dosfstools core/patch core/which extra/arch-install-scripts extra/imagemagick extra/librsvg extra/lsof extra/parted extra/qemu-img

COPY pacman.conf /etc/pacman.conf

COPY mirrorlist /etc/pacman.d/

COPY genfstab.diff /etc/

RUN patch $(which genfstab) /etc/genfstab.diff

VOLUME /build

ENTRYPOINT ["bash", "/opt/bigscreen-quickdeploy/deploy.sh"]
CMD ["-f", "/build/quickdeploy-docker.conf"]