# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r1"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=opensoar-dev "

# Commit version for 7.40.20
SRCREV = "1eee3df1a9e601ec1e452e175cece77ebb246e72"

BOOST_VERSION = "1.83.0"
BOOST_SHA256HASH = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e"

require opensoar.inc
