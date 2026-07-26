FROM archlinux:latest

WORKDIR /build

RUN pacman -Syy --noconfirm core/diffutils core/dosfstools core/gcc core/make core/patch extra/wget core/which extra/arch-install-scripts extra/imagemagick extra/librsvg extra/lsof extra/parted extra/qemu-img

RUN mkdir -p /opt/bigscreen-quickdeploy/mediabox

COPY deploy.sh /opt/bigscreen-quickdeploy/

COPY mediabox /opt/bigscreen-quickdeploy/mediabox

RUN bash "/opt/bigscreen-quickdeploy/mediabox/install-scripts/zero-volume.sh" "/opt/bigscreen-quickdeploy/" "BUILD"

COPY pacman.conf /etc/pacman.conf

COPY mirrorlist /etc/pacman.d/

COPY genfstab.diff /etc/

RUN patch $(which genfstab) /etc/genfstab.diff

VOLUME /build

ENTRYPOINT ["bash", "/opt/bigscreen-quickdeploy/deploy.sh"]
CMD ["-f", "/build/quickdeploy-docker.conf"]