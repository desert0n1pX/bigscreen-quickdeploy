FROM archlinux:latest

WORKDIR /build

RUN mkdir -p /opt/bigscreen-quickdeploy/mediabox

COPY deploy.sh /opt/bigscreen-quickdeploy/

COPY mediabox /opt/bigscreen-quickdeploy/mediabox

RUN pacman -Syy --noconfirm core/which core/dosfstools extra/lsof extra/parted extra/qemu-img extra/arch-install-scripts

COPY pacman.conf /etc/pacman.conf

COPY mirrorlist /etc/pacman.d/

VOLUME /build

ENTRYPOINT ["bash", "/opt/bigscreen-quickdeploy/deploy.sh"]
CMD ["-f", "/build/quickdeploy-docker.conf"]