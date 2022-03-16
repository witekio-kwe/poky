# Common infrastructure for Python packages that use PEP-517 compliant packaging.
# https://www.python.org/dev/peps/pep-0517/
#
# This class will build a wheel in do_compile, and use pypa/installer to install
# it in do_install.

DEPENDS:append = " python3-installer-native"

# Where to execute the build process from
PEP517_SOURCE_PATH ?= "${S}"

# The PEP517 build API entry point
PEP517_BUILD_API ?= "unset"

# The directory where wheels will be written
PEP517_WHEEL_PATH ?= "${WORKDIR}/dist"

# The interpreter to use for installed scripts
PEP517_INSTALL_PYTHON = "python3"
PEP517_INSTALL_PYTHON:class-native = "nativepython3"

# pypa/installer option to control the bytecode compilation
INSTALL_WHEEL_COMPILE_BYTECODE ?= "--compile-bytecode=0"

# When we have Python 3.11 we can parse pyproject.toml to determine the build
# API entry point directly
python_pep517_do_compile () {
    cd ${PEP517_SOURCE_PATH}
    nativepython3 -c "import ${PEP517_BUILD_API} as api; api.build_wheel('${PEP517_WHEEL_PATH}')"
}
do_compile[cleandirs] += "${PEP517_WHEEL_PATH}"

python_pep517_do_install () {
    COUNT=$(find ${PEP517_WHEEL_PATH} -name '*.whl' | wc -l)
    if test $COUNT -eq 0; then
        bbfatal No wheels found in ${PEP517_WHEEL_PATH}
    elif test $COUNT -gt 1; then
        bbfatal More than one wheel found in ${PEP517_WHEEL_PATH}, this should not happen
    fi

    nativepython3 -m installer ${INSTALL_WHEEL_COMPILE_BYTECODE} --interpreter "${USRBINPATH}/env ${PEP517_INSTALL_PYTHON}" --destdir=${D} ${PEP517_WHEEL_PATH}/*.whl
}

# A manual do_install that just uses unzip for bootstrapping purposes. Callers should DEPEND on unzip-native.
python_pep517_do_bootstrap_install () {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}
    unzip -d ${D}${PYTHON_SITEPACKAGES_DIR} ${PEP517_WHEEL_PATH}/*.whl
}

EXPORT_FUNCTIONS do_compile do_install
