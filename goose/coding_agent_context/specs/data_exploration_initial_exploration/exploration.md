# Data Exploration Brief: Initial data exploration

## Data Sources
List every data source to explore, one per bullet. Include format, location,
and approximate size when known.

- `s3://srs-prod/sherpa/training/final_data/aggregation/2025-02-01/part-00000-7184dfd4-a31c-440a-a20e-ec3fd3d00ddf-c000.csv` — CSV, ~8 GB, training data
- `s3://srs-prod/sherpa/training/final_data/single/2025-04-01/part-00000-b3687013-470e-435d-a8e7-a84567c6c9e8-c000.csv` — test data

## Environment & Credentials
Any runtime configuration the Docker container needs to access the data.

| Variable / Setting | Value | Description |
|--------------------|-------|-------------|
| `AWS_PROFILE` | `spascience` | AWS profile for S3 access |
| `AWS_DEFAULT_REGION` | `us-east-1` | AWS region |

## Context
I do not have any information about this data yet. I know it can take a long time to load the training data.
So for the initial investigation maybe only late the data partially to get a first sense of what is in there

The data is part of the SHERPA model training and evaluation, that can be seen in `Model Training_documented.py`

There has been some analyis work done before in a few iterations. For the beginning just familiarize yourself with the history and suggest the next steps.

## Initial Questions (optional)

- What is the structure of the data?
- What kind of features are available?
- What is the type of the features?

## Docker Preferences
| Setting | Value | Notes |
|---------|-------|-------|
| `USE_PACKAGE_DOCKER` | `false` | Extend existing project Dockerfile or create dedicated one |
| Extra pip packages | `plotly`, `geopandas` | This is just an example. Add apackages as needed for the exploration |
| GPU required | `false` | Whether GPU support is needed |

Keep in mind there was already quite some work done. Please look into `docker/data_exploration_initial_exploartion/` for the docker configurations.
There is also the `run.sh` script, that when running it as `run.sh process` should be used to do the actual data processing step
