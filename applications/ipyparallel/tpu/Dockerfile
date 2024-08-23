FROM python:3.10-slim-bullseye 

RUN pip install --upgrade pip

RUN pip install ipyparallel
RUN pip install -U "jax[tpu]" -f https://storage.googleapis.com/jax-releases/libtpu_releases.html

RUN mkdir -p /app/ipp