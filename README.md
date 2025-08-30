# The Green Web Foundation Dataset Browser

This is source code for the green web foundation datasets browser, visible at https://datasets.thegreenwebfoundation.org.

This is a lightly modified  of the fantastic Datasette project, led by Simon Willison. If you have data you are interested in publishing, it's a fantastic tool.

## Installation

This project uses uv by default, meaning dependencies are installe dy default when you use the supported commands listed in "Usage" and "Deployment". 

However, if you prefer, it should still work using python's default package manager.

To install it, create a virtual environment, and install the required libraries, and then run datasette.

```
python -m venv ven
python -m pip install
source .venv/bin/activate

datasette . -h 0.0.0.0
```

### Usage

This project uses [just](https://just.systems), for automating common tasks. To run the dataset locally, type just to see the options available, and then use the `serve` command to run a local server.

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
