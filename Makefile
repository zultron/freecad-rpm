# Targets:
#
# tarball:  create a tarball


# Input params
# If BUMPREL==1, then increment the last digit of OLDRELEASE
BUMPREL := 0
COMPRESSOR := gzip
TARBALL_EXT := .tar.gz

# RPM info
# name of specfile
SPECFILE := $(shell zpkg gimmespec)
# name of RPM
PACKAGE := $(shell rpm -q --specfile ${SPECFILE} --qf='%{name}\n' | head -1)
# RPM version
VERSION := $(shell rpm -q --specfile ${SPECFILE} --qf='%{version}\n' | head -1)
# Changelog date
CHANGELOGDATE := $(shell date '+%a %b %_d %Y')

# old release info
# RPM release, before we start, less %{dist}
OLDRELEASEFULL := $(shell basename `rpm -q --qf='%{release}\n' --specfile ${SPECFILE} -D 'dist .dist' | head -1 | sed 's/\.dist$$//'`)
# RPM release, before we start, less .{pre|rc}#.<date>git<commit>
OLDRELEASE := $(shell echo ${OLDRELEASEFULL} | sed 's/\.\(pre\|rc\)[0-9]\.[0-9][0-9]*git[0-9a-f][0-9a-f]*$$//')
# Any .pre# or .rc# version
PREORRC := $(shell echo ${OLDRELEASEFULL} | sed -n 's/[.0-9]*\.\(\(pre\|rc\)[0-9]\)\.[0-9][0-9]*git[0-9a-f][0-9a-f]*$$/\1/ p')
DOTPREORRC := $(shell test -n "${PREORRC}" && echo .${PREORRC})

# git info
# directory with git source
SUBMODULE := $(shell cat .gitmodules | awk '/path =/{print $$3}')
COMMIT := $(shell cd ${SUBMODULE}; git log -1 --pretty=format:"%h")
# date in YYYYMMDD format
COMMITDATE := $(shell date -d "`cd ${SUBMODULE}; git log -1 --pretty=format:%ci`" +%Y%m%d)
GITREL := ${COMMITDATE}git${COMMIT}

# new release info
ifeq (${BUMPREL},0)
NEWRELEASE := ${OLDRELEASE}
else
NEWRELEASE := $(shell echo ${OLDRELEASE} | awk -F . '{OFS=FS; $$NF = $$NF+1; print $$0}')
endif
NEWRELEASEFULL := ${NEWRELEASE}${DOTPREORRC}.${GITREL}

# tarball info
TARBALL := ${PACKAGE}-${VERSION}${PREORRC}.${GITREL}${TARBALL_EXT}

# committer info
EMAIL := $(shell git config --get user.email)
NAME := $(shell git config --get user.name)



all:  ${TARBALL} specfile
tarball:  ${TARBALL}

${TARBALL}:
	(cd ${SUBMODULE}; \
	git archive --prefix=${PACKAGE}-${VERSION}${PREORRC}/ HEAD) | ${COMPRESSOR} > ${TARBALL}
	md5sum ${TARBALL} > sources

# update the specfile with git info
specfile:
	if [ '${OLDRELEASEFULL}' = '${NEWRELEASEFULL}' ]; then \
		echo -e "\n\n*** Release has not changed; exiting" 2>&1; \
		exit 1; \
	fi; \
	sed -i \
		-e "/%global _gitrel/c %global _gitrel    ${GITREL}" \
		-e "/^Release:/s/${OLDRELEASE}/${NEWRELEASE}/" \
		-e "/%changelog/a \
* ${CHANGELOGDATE} ${NAME} <${EMAIL}> - ${VERSION}-${NEWRELEASE}${DOTPREORRC}\n\
- Update to ${VERSION}-${GITREL}\n" \
		${PACKAGE}.spec

info:
	@echo 'options:'
	@echo 'BUMPREL:        ${BUMPREL}'
	@echo
	@echo 'rpm info:'
	@echo 'SPECFILE:       ${SPECFILE}'
	@echo 'PACKAGE:        ${PACKAGE}'
	@echo 'VERSION:        ${VERSION}'
	@echo
	@echo 'old release info:'
	@echo 'OLDRELEASEFULL: ${OLDRELEASEFULL}'
	@echo 'OLDRELEASE:     ${OLDRELEASE}'
	@echo 'PREORRC:        ${PREORRC}'
	@echo 'DOTPREORRC:     ${DOTPREORRC}'
	@echo
	@echo 'git info:'
	@echo 'SUBMODULE:      ${SUBMODULE}'
	@echo 'COMMITDATE:     ${COMMITDATE}'
	@echo 'CHANGELOGDATE:  ${CHANGELOGDATE}'
	@echo 'GITREL:         ${GITREL}'
	@echo 
	@echo 'new release info:'
	@echo 'NEWRELEASE:     ${NEWRELEASE}'
	@echo 'NEWRELEASEFULL: ${NEWRELEASEFULL}'
	@echo
	@echo 'tarball info:'
	@echo 'TARBALL:        ${TARBALL}'
	@echo
	@echo 'commit info:'
	@echo 'EMAIL:          ${EMAIL}'
	@echo 'NAME:           ${NAME}'
	@echo 'COMMIT_DATE:    ${COMMIT_@@@@@DATE}'
