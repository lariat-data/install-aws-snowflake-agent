FROM --platform=linux/amd64 lariatdata/install-aws-base:latest

WORKDIR /workspace

COPY . /workspace

RUN chmod +x /workspace/init-and-apply.sh

ENTRYPOINT ["sh", "-c", "/workspace/init-and-apply.sh"]
