# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

BITBAKE_VERSION = branches/bitbake-1.8

FSO_STABLE_MILESTONE = milestone3
FSO_STABLE_VERSION = HEAD 

SHR_STABLE_MILESTONE = milestone1
SHR_STABLE_VERSION = HEAD 

.PHONY: all
all: update build

.PHONY: prefetch
prefetch: prefetch-fso-unstable prefetch-fso-testing prefetch-fso-${FSO_STABLE_MILESTONE} \
	  prefetch-shr-unstable prefetch-shr-testing prefetch-shr-${SHR_STABLE_MILESTONE}

.PHONY: build
build:
	[ ! -e fso-unstable ]                 || ${MAKE} fso-unstable-image
	[ ! -e fso-testing ]                  || ${MAKE} fso-testing-image
#	[ ! -e fso-${FSO_STABLE_MILESTONE} ]  || ${MAKE} fso-${FSO_STABLE_MILESTONE}-image
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-image
#	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-image
#	[ ! -e shr-${SHR_STABLE_MILESTONE} ]  || ${MAKE} shr-${SHR_STABLE_MILESTONE}-image
	[ ! -e fso-unstable ]                 || ${MAKE} fso-unstable-packages
	[ ! -e fso-testing ]                  || ${MAKE} fso-testing-packages
#	[ ! -e fso-${FSO_STABLE_MILESTONE} ]  || ${MAKE} fso-${FSO_STABLE_MILESTONE}-packages

.PHONY: setup
setup:  setup-common setup-bitbake setup-openembedded \
	setup-fso-unstable setup-fso-testing setup-fso-${FSO_STABLE_MILESTONE} \
	setup-shr-unstable setup-shr-testing setup-shr-${SHR_STABLE_MILESTONE}

.PHONY: update
update: update-common update-bitbake update-openembedded
	[ ! -e shr ] || ${MAKE} update-shr

.PHONY: status
status: status-common status-bitbake status-openembedded
	[ ! -e shr ] || ${MAKE} status-shr

.PHONY: clobber
clobber: clobber-fso-unstable clobber-fso-testing clobber-fso-${FSO_STABLE_MILESTONE} \
	 clobber-shr-unstable clobber-shr-testing clobber-shr-${SHR_STABLE_MILESTONE}

.PHONY: distclean
distclean: distclean-bitbake distclean-openembedded \
	 distclean-fso-unstable distclean-fso-testing distclean-fso-${FSO_STABLE_MILESTONE} \
	 distclean-shr-unstable distclean-shr-testing distclean-shr-${SHR_STABLE_MILESTONE}

.PHONY: prefetch-%
prefetch-%: %/.configured
	( cd $* ; ${MAKE} prefetch )

.PHONY: fso-%-image
fso-%-image: fso-%/.configured
	( cd fso-$* ; \
	  ${MAKE} setup-image-fso-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k image )
	( cd fso-$* ; \
	  ${MAKE} setup-image-fso-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k image )

.PHONY: fso-%-packages
fso-%-packages: fso-%/.configured
	( cd fso-$* ; \
	  ${MAKE} setup-image-fso-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k distro index )
	( cd fso-$* ; \
	  ${MAKE} setup-image-fso-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k distro index )

.PHONY: fso-%-index
fso-%-index: fso-%/.configured
	( cd fso-$* ; \
	  ${MAKE} setup-image-fso-image ; \
	  ${MAKE} -k index)

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

.PHONY: shr-%-packages
shr-%-packages: shr-%/.configured
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
	( git clone http://shr.bearstech.com/repo/shr-makefile.git common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	touch common/.git/config

.PHONY: setup-bitbake
.PRECIOUS: bitbake/.svn/entries
setup-bitbake bitbake/.svn/entries:
	[ -e bitbake/.svn/entries ] || \
	( svn co svn://svn.berlios.de/bitbake/${BITBAKE_VERSION} bitbake )
	touch bitbake/.svn/entries

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config:
	[ -e openembedded/.git/config ] || \
	( git clone git://git.openembedded.net/openembedded openembedded ; \
	  cd openembedded ; \
	  git config --add remote.origin.fetch '+refs/heads/*:refs/remotes/*' )
	( cd openembedded && \
	  ( git branch | egrep -e ' org.openembedded.dev$$' > /dev/null || \
	    git checkout -b org.openembedded.dev --track origin/org.openembedded.dev ))
	( cd openembedded && git checkout org.openembedded.dev )
	touch openembedded/.git/config

.PHONY: setup-shr
.PRECIOUS: shr/.svn/entries
setup-shr shr/.svn/entries:
	[ -e shr/.git/config ] || \
	( git clone http://shr.bearstech.com/repo/shr-overlay.git shr )
	touch shr/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured

.PRECIOUS: setup-fso-${FSO_STABLE_MILESTONE}
setup-fso-${FSO_STABLE_MILESTONE}:
	${MAKE} fso-${FSO_STABLE_MILESTONE}/.configured
	rm -f fso-${FSO_STABLE_MILESTONE}/.configured
	rm -rf fso-${FSO_STABLE_MILESTONE}/openembedded
	( cd fso-${FSO_STABLE_MILESTONE} ; \
	  git clone ../openembedded ; \
	  cd openembedded ; \
	  git checkout -b ${FSO_STABLE_MILESTONE} ${FSO_STABLE_VERSION} )
	touch fso-${FSO_STABLE_MILESTONE}/.configured

.PRECIOUS: fso-%/.configured
fso-%/.configured: common/.git/config bitbake/.svn/entries openembedded/.git/config
	[ -d fso-$* ] || ( mkdir -p fso-$* )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e fso-$*/Makefile ] || ( cd fso-$* ; ln -sf ../common/openembedded.mk Makefile )
	[ -e fso-$*/setup-env ] || ( cd fso-$* ; ln -sf ../common/setup-env . )
	[ -e fso-$*/downloads ] || ( cd fso-$* ; ln -sf ../downloads . )
	[ -e fso-$*/bitbake ] || ( cd fso-$* ; ln -sf ../bitbake . )
	[ -e fso-$*/openembedded ] || ( cd fso-$* ; ln -sf ../openembedded . )
	[ -d fso-$*/conf ] || ( mkdir -p fso-$*/conf )
	[ -e fso-$*/conf/site.conf ] || ( cd fso-$*/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e fso-$*/conf/auto.conf ] || ( \
		echo "DISTRO = \"openmoko\"" > fso-$*/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> fso-$*/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"fso-image\"" >> fso-$*/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"openmoko-feed\"" >> fso-$*/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> fso-$*/conf/auto.conf ; \
	)
	[ -e fso-$*/conf/local.conf ] || ( \
		echo "# require conf/distro/include/moko-autorev.inc" > fso-$*/conf/local.conf ; \
		echo "# require conf/distro/include/fso-autorev.inc" >> fso-$*/conf/local.conf ; \
	)
	rm -rf fso-$*/tmp/cache
	touch fso-$*/.configured

.PRECIOUS: shr-%/.configured
shr-%/.configured: common/.git/config bitbake/.svn/entries openembedded/.git/config shr/.svn/entries
	[ -d shr-$* ] || ( mkdir -p shr-$* )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-$*/Makefile ] || ( cd shr-$* ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-$*/setup-env ] || ( cd shr-$* ; ln -sf ../common/setup-env . )
	[ -e shr-$*/downloads ] || ( cd shr-$* ; ln -sf ../downloads . )
	[ -e shr-$*/bitbake ] || ( cd shr-$* ; ln -sf ../bitbake . )
	[ -e shr-$*/openembedded ] || ( cd shr-$* ; ln -sf ../openembedded . )
	[ -e shr-$*/shr ] || ( cd shr-$* ; ln -sf ../shr . )
	[ -d shr-$*/conf ] || ( mkdir -p shr-$*/conf )
	[ -e shr-$*/conf/site.conf ] || ( cd shr-$*/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-$*/conf/auto.conf ] || ( \
		echo "DISTRO = \"openmoko\"" > shr-$*/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-$*/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-image\"" >> shr-$*/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"openmoko-feed\"" >> shr-$*/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-$*/conf/auto.conf ; \
	)
	[ -e shr-$*/conf/local.conf ] || ( \
		echo "# require conf/distro/include/moko-autorev.inc" > shr-$*/conf/local.conf ; \
		echo "# require conf/distro/include/fso-autorev.inc" >> shr-$*/conf/local.conf ; \
		echo "BBFILES += \"\$${TOPDIR}/shr/openembedded/packages/*/*.bb\"" >> shr-$*/conf/local.conf ; \
		echo "BB_GIT_CLONE_FOR_SRCREV = \"1\"" >> shr-$*/conf/local.conf ; \
		echo "OE_ALLOW_INSECURE_DOWNLOADS=1" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcrevs.inc" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcdates.inc" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-$*/conf/local.conf ; \
	)
	rm -rf shr-$*/tmp/cache
	touch shr-$*/.configured

.PHONY: update-common
update-common: common/.git/config
	( cd common ; git pull )

.PHONY: update-bitbake
update-bitbake: bitbake/.svn/entries
	( cd bitbake ; svn up )

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	( cd openembedded ; git pull )

.PHONY: update-shr
update-shr: shr/.svn/entries
	( cd shr ; git pull )

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-bitbake
status-bitbake: bitbake/.svn/entries
	( cd bitbake ; svn status )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

.PHONY: status-shr
status-shr: shr/.svn/entries
	( cd shr ; git status )

.PHONY: clobber-%
clobber-%:
	[ ! -e $*/Makefile ] || ( cd $* ; ${MAKE} clobber )

.PHONY: distclean-bitbake
distclean-bitbake:
	rm -rf bitbake

.PHONY: distclean-openembedded
distclean-openembedded:
	rm -rf openembedded

.PHONY: distclean-shr
distclean-shr:
	rm -rf shr

.PHONY: distclean-%
distclean-%:
	rm -rf $*

.PHONY: push
push: push-common

.PHONY: push-common
push-common: update-common
	( cd common ; git push --all ssh://git@git.freesmartphone.org/fso-makefile.git )

# End of Makefile
