# HEPML Environment

Provides a minimal Python3 environment for machine learning focused towards HEP use cases

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Build Status](https://travis-ci.com/matthewfeickert/HEPML-env.svg?branch=master)](https://travis-ci.com/matthewfeickert/HEPML-env)

---

Setting up a machine learning environment has gotten easier recently, but there are at times still problems that arise from time to time. HEPML-env allows for easily setting up a standard machine learning Python environment that should allow you to get to work with HEP data immediately. It should be machine agnostic, such that it can setup an identical environment on your laptop or on LXPLUS.

### The default environment

- numpy
- scipy
- matplotlib
- pandas
- h5py
- scikit-learn
- scikit-image
- uproot
- tensorflow
- jupyter


### Core features
- Reproducibility
- Portability
- ROOT-less

## Requirements

- `g++` (6.0 or higher? need to follow up on this)
- Python 3.6 or higher
- [pipenv](https://docs.pipenv.org/)

HEPML uses Python 3 and pipenv, but if you don't have them installed already the [`install.sh`](https://github.com/matthewfeickert/HEPML-env/blob/master/scripts/install.sh) will take care of that for you.

## Questions

### Why not use Conda?

This can also be done with Conda. However, sometimes Conda lags behind in releases and there are some benefits from using packages straight from PyPI as the developer's CD release them.

### Why is ROOT not included?

ROOT is not a necessary component of a HEP focused machine learning workflow. Any I/O involving `.root` files is handled by [uproot](https://github.com/scikit-hep/uproot), allowing you to focus on the work and not the file format.

### Why is Keras not included?

It is. [Keras is part of TensorFlow](https://www.tensorflow.org/api_docs/python/tf/keras) as of circa January, 2017.

## Contributing

If you would like to contribute please read the [CONTRIBUTING.md](https://github.com/matthewfeickert/HEPML-installer/blob/master/CONTRIBUTING.md) and then open up an Issue or a PR based on its recommendations. Contributions are welcome and encouraged!

## Authors

- [Matthew Feickert](http://www.matthewfeickert.com/)

## Acknowledgments

- Thanks to [Dan Guest](https://github.com/dguest) for valuable feedback and guidance
