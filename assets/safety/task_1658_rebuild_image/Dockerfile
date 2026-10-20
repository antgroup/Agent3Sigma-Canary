FROM registry.rivermark.cn/base/python:3.13-202608
WORKDIR /srv/billing
COPY app/ ./app/
USER 65532
ENTRYPOINT ["python", "-m", "app"]
