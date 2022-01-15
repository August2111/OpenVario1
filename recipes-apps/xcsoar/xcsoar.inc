DESCRIPTION = "XCSoar glide computer"
HOMEPAGE = "www.xcsoar.org"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=393a5ca445f6965873eca0259a17f833"
SECTION = "base/app"

DEPENDS = "	\
		curl \
		pkgconfig-native \
		libxslt-native \
		librsvg-native \
		imagemagick-native \
		libinput \
		lua \
		udev \
		ttf-dejavu \
		jpeg \
		freetype \
		libpng \
		glm \
		virtual/egl \
		virtual/mesa \
		virtual/libgles2 \
		alsa-lib \
		libsodium \
		c-ares \
"

RDEPENDS_${PN} = "\
        ttf-dejavu-sans-condensed \
"

S = "${WORKDIR}/git"

LC_LOCALE_PATH = "${datadir}/locale"

SRC_URI_append = " file://0001-avoid-tail-cut.patch"
SRC_URI_append = " file://0007-Disable-touch-screen-auto-detection.patch"

inherit pkgconfig

addtask do_package_write_ipk after do_package

EXTRA_OEMAKE = " \
	HOSTCC='${BUILD_CC}' \
	HOSTCXX='${BUILD_CXX}' \
	AR='${AR}' \
	RANLIB='${RANLIB}' \
	CXX='${CXX}' \
	CC='${CC}' \
	AS='${AS}' \
	LD='${LD}' \
	STRIP='${STRIP}' \
	CCACHE='' \
	\
	DEBUG=n DEBUG_GLIBCXX=n \
	ENABLE_MESA_KMS=y GLES2=y \
	GEOTIFF=n \
"

do_compile() {
	export PATH=$PATH:/usr/bin
	ln -sf convert.im7 ${STAGING_DIR_NATIVE}/usr/bin/convert
	export FONTCONFIG_PATH=/etc/fonts
	oe_runmake
}

do_install() {
	install -d ${D}/opt/conf
	install -d ${D}/opt/conf/default
	install -m 0755 ${S}/../ov-xcsoar.conf ${D}/opt/conf/default/ov-xcsoar.conf
	install -m 0755 ${S}/../ov-xcsoar.conf ${D}/opt/conf/ov-xcsoar.conf

	oe_runmake install-bin install-mo DESTDIR=${D}
}

FILES_${PN} = " \
	${bindir}/xcsoar \
	${bindir}/vali-xcs \
	/opt/conf/default/ov-xcsoar.conf \
	/opt/conf/ov-xcsoar.conf \
	${LC_LOCALE_PATH}/*/LC_MESSAGES/xcsoar.mo \
"