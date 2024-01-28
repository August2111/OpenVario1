require openvario-base-image.bb

# image size -> 512MB
IMAGE_ROOTFS_SIZE ?= "475136"

IMAGE_INSTALL += "\
    opensoar \
    xcsoar \
    xcsoar-menu \
    xcsoar-profiles \
    xcsoar-maps-default \
    caltool \
    sensord \
    variod \
    ovmenu-ng \
    ovmenu-xcs \
"

IMAGE_INSTALL += "e2fsprogs-mke2fs "

export IMAGE_BASENAME = "openvario-image"
