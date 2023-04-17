FROM --platform=linux/amd64 lariatdata/install-aws-base:latest

RUN apk add --no-cache gcc g++ libffi-dev
RUN pip3 install prompt-toolkit
RUN pip3 install --no-deps ruamel.yaml

WORKDIR /workspace

COPY . /workspace

RUN pip install snowflake_connector_python-3.0.2-py3-none-any.whl

RUN chmod +x /workspace/init-and-apply.sh

ENTRYPOINT ["sh", "-c", "/workspace/init-and-apply.sh"]
