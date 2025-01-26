# The Green Web Foundation Dataset Browser

This is source code for the green web foundation datasets browser, visible at https://datasets.thegreenwebfoundation.org.

This is a lightly modified  of the fantastic Datasette project, led by Simon Willison. If you have data you are interested in publishing, it's a fantastic tool.

## Installation

This project used pipenv by default, but

To install it, create a virtual environment, and install the required libraries

```
python -m venv venv
pip install pipenv
source venv/bin/activate

pipenv install
```

### Usage

```
just serve
```


# Deploying

```
just release
```

# Contributing



# Licensing

The code is open source - [Apache 2.0](https://choosealicense.com/licenses/apache-2.0/)

The data is available on the [Open Database License](https://opendatacommons.org/licenses/odbl/summary/index.html). Y
