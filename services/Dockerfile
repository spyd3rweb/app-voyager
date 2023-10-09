FROM registry.airship.cloud/voyager:latest

VOLUME /data
VOLUME /home/pn/app/logsS

# https://github.com/duckdb/duckdb/issues/8802, https://github.com/chroma-core/chroma/issues/1069
RUN pip install --force-reinstall pandas==2.0.3 

COPY Voyager /home/pn/app
WORKDIR /home/pn/app/

ENV PATH=$PATH:/home/pn/.local/bin:/home/pn/app/voyager:

# All images have a default user pn with uid 1000 and gid 1000.
# python require Error: EACCES: permission denied, open '/usr/local/lib/python3.9/site-
# https://stackoverflow.com/questions/44633419/no-access-permission-error-with-npm-global-install-on-docker-image
# USER pn

# Expose the default API port and debug port
EXPOSE 3000
EXPOSE 5678

# Start voyager
CMD ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "--wait-for-client", "voyager_inference.py"]