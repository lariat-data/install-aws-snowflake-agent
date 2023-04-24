### Intro

This repository contains the Docker image and dependencies for the Lariat agent installer for Snowflake on AWS

### Structure

### Building locally
You may build and run a local version of this image using `docker`.

```docker
docker build -t <my_image_name> .
```




Requires `python3` (in a venv if you prefer)

`pip install -r requirements.txt`

Edit the `SNOWFLAKE_*` variables in the `install_snowflake_agent.py` file

`SNOWFLAKE_PASSWORD=<your_snowflake_password> python install_snowflake_agent.py`
