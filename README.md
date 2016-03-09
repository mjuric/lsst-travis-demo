[![Build Status](https://travis-ci.org/mjuric/lsst-travis-demo.svg?branch=master)](https://travis-ci.org/mjuric/lsst-travis-demo)

# Getting the LSST stack within the TravisCI environment

## For the impatient

Look at [.travis.yml](.travis.yml) and [ci/install.sh](ci/install.sh) for how it's done.

## More details

All of the logic is in `ci/install.sh`. Call it from the `install` clause of
`.travis.yml`.  It takes the conda packages to install as arguments
(typically, the LSST packages your code needs to run).

The first time it's run, `ci/install.sh` will:

 1. Install Miniconda 2 into `$HOME/miniconda` on the Travis build host
 1. Install the requested packages using `conda` (use `lsst-distrib` for the DM stack, `lsst-sims` for simulations)
 1. Cache the `$HOME/miniconda` directory for speeding up subsequent runs

. This first run typically [takes ~6-11 minutes](https://travis-ci.org/mjuric/lsst-travis-demo)
(on a containerized TravisCI host).  On subsequent runs, the script will
re-use the cache it created.  When setting up from cache, it will take about
~1-2 minutes.

n.b: for caching to work, make sure you have the following entry:
```
cache:
  directories:
  - $HOME/miniconda.tarball
```
in your `.travis.yml`. 

To use the stack from within Travis, add the miniconda directory to your path in the
`script:` section of `.travis.yml` and source `setup-eups.sh`. Here's a complete example:
```
language: C

install:
  - ./ci/install.sh lsst-distrib

cache:
  directories:
  - $HOME/miniconda.tarball

# A trivial example to show that this worked
script:
  - export PATH="$HOME/miniconda/bin:$PATH"
  - source eups-setups.sh
  - setup afw
  - python -c 'import lsst.afw; print lsst.afw.__file__'
```

The `language:` section doesn't matter, as we'll be using Python and the
related tools from Anaconda.  Use whichever language makes Travis spin up
the container fastest.

## Caveats

* If you change the arguments passed to `ci/install.sh`, make sure to
  (manually) wipe the TravisCI cache (otherwise they won't get picked up). 
  Bonus points: teach `ci/install.sh` to wipe the cache if it detects the
  arguments have changed, and send me a PR.

* If you need to build C/C++ sources, use Anaconda's `gcc` by adding it
  as an argument to `ci/install.sh`. E.g.: `./ci/install.sh gcc lsst-distrib`.
