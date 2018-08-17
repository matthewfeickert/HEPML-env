# HEPML Environment

Provides a minimal Python3 environment for machine learning focused towards HEP use cases

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Build Status](https://travis-ci.com/matthewfeickert/HEPML-env.svg?branch=master)](https://travis-ci.com/matthewfeickert/HEPML-env)


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
- [keras](https://github.com/keras-team/keras)
- [jupyter](https://github.com/jupyter)


### Core features
- Reproducibility
- Portability
- ROOT-less

## Table of Contents
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:0 orderedList:0 -->

- [Requirements](#requirements)
- [Installation and setup](#installation-and-setup)
- [Questions](#questions)
	- [Why were the packages chosen for the default environment?](#why-were-the-packages-chosen-for-the-default-environment)
	- [Why not use Conda?](#why-not-use-conda)
	- [What if I just want to use pip?](#what-if-i-just-want-to-use-pip)
	- [Why is ROOT not included?](#why-is-root-not-included)
	- [Why is Keras included? It is part of TensorFlow now.](#why-is-keras-included-it-is-part-of-tensorflow-now)
	- [Will you support Python 2?](#will-you-support-python-2)
- [Contributing](#contributing)
- [Authors](#authors)
- [Acknowledgments](#acknowledgments)

<!-- /TOC -->

## Requirements

- GNU
    - gcc/g++ (5.4 or higher is recommended)
    - zlibc
    - zlib1g-dev
    - libssl-dev
    - wget
    - make
    - Bash
- Python 3.6 or higher
- [pipenv](https://docs.pipenv.org/)

HEPML uses Python 3 and pipenv, but if you don't have them installed already the [`install.sh`](https://github.com/matthewfeickert/HEPML-env/blob/master/scripts/install.sh) will take care of that for you.

<details>
 <summary>Installing GNU requirements on Debian/Ubuntu</summary>

On Debian/Ubuntu the GNU requirements can be met by

```
apt install gcc g++ git zlibc zlib1g-dev libssl-dev wget make
```

</details>

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

NumPy, SciPy, Matplotlib, and Pandas represent the core of the powerful [SciPy stack](https://www.scipy.org/) (IPython is taken care of by Jupyter). h5py and uproot allow for working with [industry standard data formats](https://support.hdfgroup.org/HDF5/). scikit-learn, scikit-image, and tensorflow provide a very strong machine learning ecosystem. Keras allows for easily building NNs and training with different backends. Jupyter provides the Jupyter notebook, qtconsole, and the IPython kernel, which ties it all together for interactive computing and data exploration.

### Why not use Conda?

This can also be done with Conda. However, sometimes Conda lags behind in releases and there are some benefits from using packages straight from PyPI as the developer's CD release them. In addition, Conda requires additional space and software that is not core to the environment that we need. This is not necessarily a problem, but having a lightweight, portable, reproducible environment that can be fully installed in under 5 minutes is the goal here, and I think that pipenv is better suited for that.

However, it is recognized that Conda is incredibly popular, and even the recommended installation method for some packages. In the future a Conda `environment.yml` file that closely follows the `Pipfile` for the default environment will be released on [Anaconda cloud](https://anaconda.org/).

### What if I just want to use pip?

If you want to be in charge of your own environment management then you can use [pipenv to generate a `requirements.txt` file](https://docs.pipenv.org/advanced/#generating-a-requirements-txt) for you from the `Pipfile.lock`

```
pipenv lock --requirements > requirements.txt
```

Note that this generates a `requirements.txt` that matches the lock so `==` is used. You might want to do a search and replace with `>=` if you're going to be installing in your home environment.

### Why is ROOT not included?

ROOT is not a necessary component of a HEP focused machine learning workflow. Any I/O involving `.root` files is handled by [uproot](https://github.com/scikit-hep/uproot), allowing you to focus on the work and not the file format.

### Why is Keras included? It is part of TensorFlow now.

> [`tf.keras` is TensorFlow's implementation of the Keras API specification](https://www.tensorflow.org/guide/keras#import_tfkeras).

So while [Keras has been included as part of TensorFlow](https://www.tensorflow.org/api_docs/python/tf/keras) since circa January, 2017, the Keras library is a different standalone library then its TensorFlow module counterpart.

### Will you support Python 2?

[No](https://pythonclock.org/). Python 2's EOL date has been [officially set to 2020-01-01](https://github.com/python/devguide/pull/344). We need to move on as a community; [everyone else already has](https://python3statement.org/).

## Contributing

If you would like to contribute please read the [CONTRIBUTING.md](https://github.com/matthewfeickert/HEPML-installer/blob/master/CONTRIBUTING.md) and then open up an Issue or a PR based on its recommendations. Contributions are welcome and encouraged!

## Authors

- [Matthew Feickert](http://www.matthewfeickert.com/)

## Acknowledgments

- Thanks to [Dan Guest](https://github.com/dguest) for valuable feedback and guidance
