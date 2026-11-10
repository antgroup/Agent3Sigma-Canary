FROM python:3.13.7-slim
WORKDIR /srv/health-router
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./app.py
USER 65532:65532
ENTRYPOINT ["python", "/srv/health-router/app.py"]
