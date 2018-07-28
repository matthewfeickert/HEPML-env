# HEPML Environment

Provides a minimal Python3 environment for machine learning focused towards HEP use cases

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Build Status](https://travis-ci.com/matthewfeickert/HEPML-env.svg?branch=master)](https://travis-ci.com/matthewfeickert/HEPML-env)

---

Setting up a machine learning environment has gotten easier recently, but there are at times still problems that arise from time to time. HEPML-env allows for easily setting up a standard machine learning Python environment that should allow you to get to work with HEP data immediately. It should be machine agnostic, such that it can setup an identical environment on your laptop or on LXPLUS.

### The default environment

- [numpy](https://github.com/numpy/numpy)
- [scipy](https://github.com/scipy/scipy)
- [matplotlib](https://github.com/matplotlib/matplotlib)
- [pandas](https://github.com/pandas-dev/pandas)
- [h5py](https://github.com/h5py/h5py)
- [uproot](https://github.com/scikit-hep/uproot)
- [scikit-learn](https://github.com/scikit-learn/scikit-learn)
- [scikit-image](https://github.com/scikit-image/scikit-image)
- [tensorflow](https://github.com/tensorflow/tensorflow)
- [jupyter](https://github.com/jupyter)


### Core features
- Reproducibility
- Portability
- ROOT-less

## Requirements

- `g++` (6.0 or higher? need to follow up on this)
- Python 3.6 or higher
- [pipenv](https://docs.pipenv.org/)

HEPML uses Python 3 and pipenv, but if you don't have them installed already the [`install.sh`](https://github.com/matthewfeickert/HEPML-env/blob/master/scripts/install.sh) will take care of that for you.

## Installation and setup

1. Clone the repo

<details>
 <summary>Note on cloning on LXPLUS</summary>

When trying to use SSH with GitHub on LXPLUS it is important to make sure that your `~/.ssh/config` is properly configured. It may need to contain something along the lines of

```
Host github.com
    IdentityFile ~/.ssh/id_rsa-github
    IdentitiesOnly yes
```

</details>


2. If the above requirements are not already satisfied, run the installer

```
bash scripts/install.sh
```

3. Make a directory for your project

```
mkdir ~/projects/HEPML_project
cd ~/projects/HEPML_project
```

4. Copy the included `Pipfile` and `Pipfile.lock` to the project directory

5. Install the environment with pipenv

```
# From inside the project directory
pipenv install
```

6. Launch into the project environment with pipenv

```
pipenv shell
```

## Questions

### Why were the packages chosen for the default environment?

NumPy, SciPy, Matplotlib, and Pandas represent the core of the powerful [SciPy stack](https://www.scipy.org/) (IPython is taken care of by Jupyter). h5py and uproot allow for working with [industry standard data formats](https://support.hdfgroup.org/HDF5/). scikit-learn, scikit-image, and tensorflow provide a very strong machine learning ecosystem and Keras support. Jupyter provides the Jupyter notebook, qtconsole, and the IPython kernel, which ties it all together for interactive computing and data exploration.

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
