FROM nikolaik/python-nodejs:python3.9-nodejs18

VOLUME /data

RUN pip install debugpy cython

COPY Voyager /home/pn/app
WORKDIR /home/pn/app/
RUN pip install -e .

# https://github.com/MineDojo/Voyager/issues/120
WORKDIR /home/pn/app/voyager/env/mineflayer/mineflayer-collectblock

#RUN npm install -g npx
RUN npm install
RUN npx tsc

WORKDIR /home/pn/app/voyager/env/mineflayer
RUN npm install

#WORKDIR /home/pn/app/skill_library/ 
#RUN mkdir -p daswer123 swen128 DeveloperHarris
#RUN git clone https://github.com/daswer123/Voyager_checkpoint ./daswer123
#RUN git clone https://github.com/swen128/Voyager_checkpoint ./swen128
#RUN git clone https://github.com/DeveloperHarris/voyager_checkpoint ./DeveloperHarris

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