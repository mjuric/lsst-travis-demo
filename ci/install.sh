#!/bin/bash -xe
#
# A script to setup the Travis build environment with Miniconda
# and install the LSST stack into it
#

MINICONDA_VERSION=3.19.0				# you can use "latest" if you don't care
CHANNEL="http://research.majuric.org/conda/stable"	# the URL to the conda channel where LSST conda packages reside
PACKAGES="$@"						# the top-level LSST package you want installed (lsst-distrib for DM, lsst-sims for simulations)


CACHE_DIR="$HOME/miniconda.tarball"
CACHE_TARBALL="$CACHE_DIR/miniconda.tar.gz"

if [[ -f "$CACHE_TARBALL" ]]; then
	#
	# Restore from cached tarball
	#
	tar xzf "$CACHE_TARBALL" -C "$HOME" 
	ls -l "$HOME"
else
	#
	# Miniconda install
	#
	# Install Python 2.7 Miniconda
	rm -rf "$HOME/miniconda"
	curl -L -O "https://repo.continuum.io/miniconda/Miniconda2-$MINICONDA_VERSION-Linux-x86_64.sh"
	bash "Miniconda2-$MINICONDA_VERSION-Linux-x86_64.sh" -b -p "$HOME/miniconda"
	export PATH="$HOME/miniconda/bin:$PATH"

	#
	# Disable MKL. The stack doesn't play nice with it (symbol collisions)
	#
	conda install --yes nomkl

	#
	# Stack install
	#
	conda config --add channels "$CHANNEL"
	conda install -q --yes "$PACKAGES"		# -q is needed, otherwise TravisCI kills the job due too much output in the log (4MB)

	# Minimize our on-disk footprint
	conda clean -iltp --yes

	#
	# Pack for caching. We pack here as Travis tends to time out if it can't pack
	# the whole directory in ~180 seconds.
	#
	rm -rf "$CACHE_DIR"
	mkdir "$CACHE_DIR"
	tar czf "$HOME/tmp.tar.gz" -C "$HOME" miniconda && mv "$HOME/tmp.tar.gz" "$CACHE_TARBALL"
fi
