# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BITBAKE_VERSION = 1.10

SHR_TESTING_BRANCH_OE = shr/testing2010
SHR_UNSTABLE_BRANCH_OE = org.openembedded.dev
SHR_STABLE_BRANCH_OE = shr/stable2009

SHR_MAKEFILE_URL = "http://git.shr-project.org/repo/shr-makefile.git"

.PHONY: all
all: update build

.PHONY: setup
setup:  setup-common setup-bitbake setup-openembedded setup-shr-unstable setup-shr-testing

.PHONY: prefetch
prefetch: prefetch-shr-unstable prefetch-shr-testing

.PHONY: update
update: 
	[ ! -e common ] || ${MAKE} update-common 
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e shr-testing ] || ${MAKE} update-shr-testing 
##	[ ! -e shr-stable ] || ${MAKE} update-shr-stable
	[ ! -e bitbake ] || ${MAKE} update-bitbake 

.PHONY: build
build:
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-image
	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-image
##	[ ! -e shr-stable ]                   || ${MAKE} shr-stable-image
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-recipes
	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-recipes
##	[ ! -e shr-stable ]                   || ${MAKE} shr-stable-recipes

.PHONY: status
status: status-common status-bitbake status-openembedded

.PHONY: clobber
clobber: clobber-shr-unstable clobber-shr-testing

.PHONY: distclean
distclean: distclean-bitbake distclean-openembedded \
	 distclean-shr-unstable distclean-shr-testing

.PHONY: prefetch-%
prefetch-%: %/.configured
	( cd $* ; ${MAKE} prefetch )


.PHONY: shr-%-image
shr-%-image: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k image )
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k image )

.PHONY: shr-%-recipes
shr-%-recipes: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k distro index )
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k distro index )

.PHONY: shr-%-index
shr-%-index: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} -k index )

.PHONY: setup-common
.PRECIOUS: common/.git/config
setup-common common/.git/config:
	[ -e common/.git/config ] || \
	( echo "setting up common (Makefile)"; \
	  git clone ${SHR_MAKEFILE_URL} common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	touch common/.git/config

.PHONY: setup-bitbake
.PRECIOUS: bitbake/.git/config
setup-bitbake bitbake/.git/config:
	if [ -d bitbake/.svn ]; then \
		echo; \
		echo "ATTENTION: you still have bitbake from the svn tree!!!"; \
		echo "           bitbake changed to git - please do:"; \
		echo; \
		echo "           rm -rf bitbake && make setup-bitbake"; \
		echo; \
		exit 1;\
	fi
	[ -e bitbake/.git/config ] || \
	( echo "setting up bitbake ..."; \
	  git clone git://git.openembedded.net/bitbake bitbake; \
	  cd bitbake; \
	  git checkout ${BITBAKE_VERSION} 2>/dev/null || \
	  git checkout --no-track -b ${BITBAKE_VERSION} origin/${BITBAKE_VERSION} ; \
	  git reset --hard origin/${BITBAKE_VERSION} )

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config:
	[ -e openembedded/.git/config ] || \
	( echo "setting up openembedded"; \
	  git clone git://git.openembedded.net/openembedded openembedded )
	( cd openembedded && \
	  ( git branch | egrep -e ' org.openembedded.dev$$' > /dev/null || \
	    git checkout -b org.openembedded.dev --track origin/org.openembedded.dev ))
	( cd openembedded && git checkout org.openembedded.dev )
	touch openembedded/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured


##.PRECIOUS: shr-stable/.configured
shr-stable/.configured: common/.git/config bitbake/.git/config openembedded/.git/config
	@echo "preparing shr-stable tree"
	[ -d shr-stable ] || ( mkdir -p shr-stable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-stable/Makefile ] || ( cd shr-stable ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-stable/setup-env ] || ( cd shr-stable ; ln -sf ../common/setup-env . )
	[ -e shr-stable/downloads ] || ( cd shr-stable ; ln -sf ../downloads . )
	[ -e shr-stable/bitbake ] || ( cd shr-stable ; ln -sf ../bitbake . )
	[ -e shr-stable/openembedded ] || ( cd shr-stable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} )
	[ -d shr-stable/conf ] || ( mkdir -p shr-stable/conf )
	[ -e shr-stable/conf/site.conf ] || ( cd shr-stable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-stable/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-stable/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-stable/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-stable/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-stable/ipk/\"" >> shr-stable/conf/auto.conf ; \
	)
	[ -e shr-stable/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-stable/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-stable/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-stable/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-stable/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-stable/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-stable/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-stable/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-stable/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-stable/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-stable/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-stable/conf/local.conf ; \
	)
	[ -e shr-stable/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-stable/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${AUTOREV}" >> shr-stable/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-stable/conf/local-builds.inc ; \
	)
	[ -e shr-stable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-stable'" > shr-stable/conf/topdir.conf
	rm -rf shr-stable/tmp/cache
	touch shr-stable/.configured

.PRECIOUS: shr-testing/.configured
shr-testing/.configured: common/.git/config bitbake/.git/config openembedded/.git/config
	@echo "preparing shr-testing tree"
	[ -d shr-testing ] || ( mkdir -p shr-testing )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-testing/Makefile ] || ( cd shr-testing ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-testing/setup-env ] || ( cd shr-testing ; ln -sf ../common/setup-env . )
	[ -e shr-testing/downloads ] || ( cd shr-testing ; ln -sf ../downloads . )
	[ -e shr-testing/bitbake ] || ( cd shr-testing ; ln -sf ../bitbake . )
	[ -e shr-testing/openembedded ] || ( cd shr-testing ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} )
	[ -d shr-testing/conf ] || ( mkdir -p shr-testing/conf )
	[ -e shr-testing/conf/site.conf ] || ( cd shr-testing/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-testing/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-testing/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-testing/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-testing/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-testing/ipk/\"" >> shr-testing/conf/auto.conf ; \
	)
	[ -e shr-testing/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-testing/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-testing/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-testing/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-testing/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-testing/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-testing/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-testing/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-testing/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-testing/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-testing/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-testing/conf/local.conf ; \
	)
	[ -e shr-testing/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-testing/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${AUTOREV}" >> shr-testing/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-testing/conf/local-builds.inc ; \
	)
	[ -e shr-testing/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-testing'" > shr-testing/conf/topdir.conf
	rm -rf shr-testing/tmp/cache
	touch shr-testing/.configured

.PRECIOUS: shr-unstable/.configured
shr-unstable/.configured: common/.git/config bitbake/.git/config openembedded/.git/config
	@echo "preparing shr-unstable tree"
	[ -d shr-unstable ] || ( mkdir -p shr-unstable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-unstable/Makefile ] || ( cd shr-unstable ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-unstable/setup-env ] || ( cd shr-unstable ; ln -sf ../common/setup-env . )
	[ -e shr-unstable/downloads ] || ( cd shr-unstable ; ln -sf ../downloads . )
	[ -e shr-unstable/bitbake ] || ( cd shr-unstable ; ln -sf ../bitbake . )
	[ -e shr-unstable/openembedded ] || ( cd shr-unstable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} )
	[ -d shr-unstable/conf ] || ( mkdir -p shr-unstable/conf )
	[ -e shr-unstable/conf/site.conf ] || ( cd shr-unstable/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-unstable/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-unstable/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-unstable/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-unstable/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-unstable/ipk/\"" >> shr-unstable/conf/auto.conf ; \
	)
	[ -e shr-unstable/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-unstable/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-unstable/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-unstable/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-unstable/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-unstable/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-unstable/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-unstable/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-unstable/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-unstable/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-unstable/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
	)
	[ -e shr-unstable/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-unstable/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${GITSHA}" >> shr-unstable/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-unstable/conf/local-builds.inc ; \
	)
	[ -e shr-unstable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-unstable'" > shr-unstable/conf/topdir.conf
	rm -rf shr-unstable/tmp/cache
	touch shr-unstable/.configured


.PHONY: update-common
update-common: common/.git/config
	@echo "updating common (Makefile)"
	( cd common ; git pull )

.PHONY: update-bitbake
update-bitbake: bitbake/.git/config
	@echo "updating bitbake"
	( cd bitbake ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BITBAKE_VERSION} 2>/dev/null || \
	  git checkout --no-track -b ${BITBAKE_VERSION} origin/${BITBAKE_VERSION} ; \
	  git reset --hard origin/${BITBAKE_VERSION} )

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	@echo "updating openembedded"
	( cd openembedded ; git pull || ( \
      echo ; \
      echo "!!! looks like either the OE git server has problems"; \
      echo "or you have a dirty OE tree ;)"; \
      echo "to fix that do the following:"; \
      echo "cd `pwd`; git reset --hard"; \
      echo ; \
      echo "ATTENTION: that will kill all eventual changes" ) )

.PHONY: update-shr-stable
update-shr-stable: shr-stable/.configured
	@echo "updating shr-stable tree"
	( cd shr-stable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_STABLE_BRANCH_OE} )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	@echo "updating shr-testing tree"
	( cd shr-testing/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_TESTING_BRANCH_OE} )

.PHONY: update-shr-unstable
update-shr-unstable: shr-unstable/.configured
	@echo "updating shr-unstable tree"
	( cd shr-unstable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_UNSTABLE_BRANCH_OE} )

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-bitbake
status-bitbake: bitbake/.git/config
	( cd bitbake ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

.PHONY: clobber-%
clobber-%:
	[ ! -e $*/Makefile ] || ( cd $* ; ${MAKE} clobber )

.PHONY: distclean-bitbake
distclean-bitbake:
	rm -rf bitbake

.PHONY: distclean-openembedded
distclean-openembedded:
	rm -rf openembedded

.PHONY: distclean-%
distclean-%:
	rm -rf $*

#.PHONY: push
#push: push-common

#.PHONY: push-common
#push-common: update-common
#	( cd common ; git push --all ssh://git@git.freesmartphone.org/fso-makefile.git )

# End of Makefile
