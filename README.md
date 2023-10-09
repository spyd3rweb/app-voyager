# Kubernetes deployment for Voyager and Fabric Minecraft

This [k8s application](https://cloud.google.com/code/docs/vscode/deploy-kubernetes-app) deploys an instance of [Voyager](https://github.com/MineDojo/Voyager) along with a [Fabric Minecraft](https://docker-minecraft-server.readthedocs.io/en/latest/) server with [required fabric mods](https://github.com/spyd3rweb/Voyager/blob/main/installation/fabric_mods_install.md).  It assumes you have a local deployment of a [Large Language Model (LLM) with 4K-8K token context length](https://github.com/facebookresearch/codellama/blob/main/README.md) with a compatible [OpenAI API](https://platform.openai.com/docs/api-reference), including [embeddings support](https://platform.openai.com/docs/guides/embeddings). 

\* *Note Voyager typically uses OpenAI's closed source [GPT-4](https://help.openai.com/en/articles/7127966-what-is-the-difference-between-the-gpt-4-models) as the LLM and	[text-embedding-ada-002](https://platform.openai.com/docs/guides/embeddings/types-of-embedding-models) sentence-transformers model for [embeddings](https://huggingface.co/blog/mteb).  With a local deployment you will NOT be able to reuse any of the regular [Voyager community's skill libararies](https://github.com/MineDojo/Voyager/blob/main/skill_library/README.md), which use the closed source text-embedding-ada-002, as ["you cannot mix embeddings from different models even if they have the same dimensions. They are not comparable"](https://github.com/oobabooga/text-generation-webui/blob/main/extensions/openai/README.md#embeddings-alpha)*

Minor updates to [Voyager](https://github.com/spyd3rweb/Voyager/tree/main/voyager) have been made to enable the specification of the base url for OpenAI API as well as the domain name/IP of the Minecraft host. There have also been two python files (voyager_inference.py and voyager_learn.py) created for easily running between Voyager's [inference](https://github.com/spyd3rweb/Voyager/blob/main/README.md#run-voyager-for-a-specific-task-with-a-learned-skill-library) and [learn](https://github.com/spyd3rweb/Voyager/blob/main/README.md#resume-from-a-checkpoint-during-learning) modes. 

### Temper your expectations; this is a proof of concept using "open/local" LLMs. With CodeLlama I have only had the Voyager bot successfully mine a log, never actually craft anything.  I've also had it run 160 iterations without being able to successfully complete a single task.

## Dependencies 

### Text-Generation

As a proof of concept, for local text generation I have used [oobabooga's text-generation webui](https://github.com/oobabooga/text-generation-webui) configured with [Phind CodeLlama 34B V2](https://huggingface.co/TheBloke/Phind-CodeLlama-34B-v2-GPTQ) as the LLM, the [openai extension](https://github.com/oobabooga/text-generation-webui/tree/main/extensions/openai) and the [lodestone-base-4096-v1](https://huggingface.co/Hum-Works/lodestone-base-4096-v1) sentence-transformers model for embeddings.  [CodeLlama](https://huggingface.co/blog/codellama) models are supposed to provide state-of-the-art performance in Python, C++, Java, PHP, C#, TypeScript, and Bash, and so theoretically should be able to produce the Javascript code required for Voyager's skill library.

In the future I'll create another github repo with the k8s manifests for my text-generation webui deployment, but this is an example command to use when deploying with a GPU with 24GB VRAM (ie NVIDIA RTX 3090 or Tesla P40)
```
OPENEDAI_EMBEDDING_MODEL="Hum-Works/lodestone-base-4096-v1" python3 server.py --loader llamacpp --n_batch 768 --sdp-attention --n-gpu-layers 1000000000 --n_ctx 8192 --model phind-codellama-34b-v2 --sdp-attention --extensions openai --listen --verbose
```

Be sure to configure the instruct template and config.yaml for your [model setup/preference](https://www.reddit.com/r/Oobabooga/comments/1611fd6/here_is_a_test_of_codellama34binstruct/).  

\* *Currently the k8s/voyager-deploy.yaml manifest sets the [OPENAI_API_BASE environment variable](https://github.com/search?q=repo%3Aopenai%2Fopenai-python%20OPENAI_API_BASE&type=code) to "http://webui.text-gen.svc.cluster.local:5001/v1"; set this to the url (or IP) and port of your compatible OpenAI API.*

### Persistent Volume Claim (PVC)

Ensure a PVC has been created named "minecraft-data-pvc" with one of your local cluster's [storage class and provisioners](https://kubernetes.io/docs/concepts/storage/storage-classes/).

\* *Currently the k8s/minecraft-data-pvc.yaml is commented out, as I recommend these resources be created outside of the continuous development to avoid unintentiaional cleanup and loss of data. Also to ease file management with PVC's and enable browser based edditing of config files, I highly recommend deploying an instance of [filebrowser](https://github.com/filebrowser/filebrowser).*

## [Continuous Development](https://skaffold.dev/docs/workflows/dev/)
### For development and debugging, it is highly recommended to use [Google's Cloud Code](https://cloud.google.com/code/docs/vscode/debug) for [vscode](https://code.visualstudio.com/docs/languages/python); a [skaffold configuration](https://skaffold.dev/docs/references/yaml/) is provided for build and deployment configurations as described in the following sections.

### [Skaffold Builders](https://skaffold.dev/docs/builders/)
* [Docker](https://skaffold.dev/docs/pipeline-stages/builders/docker/): In the services directory there are multiple [Dockerfiles](https://docs.docker.com/engine/reference/builder/):
  * voyager.Dockerfile - creates debuggable version of Voyager, using a prebuilt container for [python with node.js](https://github.com/nikolaik/docker-python-nodejs) and installation of all python and nodejs dependencies.
  * Dockerfile -  creates a debuggable version of Voyager, to reduce development build times, avoids reinstalling python and nodejs dependencies by using the image above and simply copies over the local git submodule for Voyager.

### [Skaffold Deployers](https://skaffold.dev/docs/deployers/)
The following skaffold configuration deploys both the voyager and fabric minecraft containers to the minecraft namespace and uses a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) between them for storage.

* [kubectl](https://skaffold.dev/docs/deployers/kubectl/): Used to apply the set of [K8S manifests](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/) to create a [skaffold debug](https://skaffold.dev/docs/workflows/debug/) configuration capable of remote python debugging

## Deployment/Debugging with vscode and Google Cloud Code

* Ensure you have installed the [Google Cloud Code extention](https://cloud.google.com/code/docs/vscode/install) for vscode.  In vscode click on the "Cloud Code" extension icon on the primary side bar.  Select "Debug on Kubernetes" which will create "Kubernetes: Run/Debug" under  development sessions.  If dependencies from the above section were satisfied, then the session will go through several stages: "Initialize Session", "Build Containers", "Render Manifests" "Deploy to Cluster", "Status Check", "Portforward URLs" and finally and "Stream Application Logs".  At this point you should be able to view the streaming logs.

* If you would like to debug, make sure to set breakpoints and click on the "Run and Debug" icon in the vscode primary side bar.  Next to "RUN AND DEBUG" select "Attach to Remote Debugpy (Python)" and it will connect to port forwarded for debugpy (ie. 5678); if you have an issue connecting double check the "Portforward URLs" from the "Kubernetes: Run/Debug" session and update the port in the ".vscode/lanch.json" accordingly.

* By default the containers will begin to execute and continue to run through breakpoints until the debugger client is attached.  If you wish to prevent execution prior to the dubugger being attached, then add "--wait-for-client" to the k8s/voyager.deploy.yaml "args" as shown below:
```
        args: ["-c", "python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client voyager_learn.py "]
```

## Troubleshooting

* Ensure that skaffold is configured for your [default image repository/registry](https://skaffold.dev/docs/environment/image-registries/). *When running the "Kubernetes: Run/Debug" you should be prompted for your default image registry.  You can also update this setting in the file ".vscode/launch.json", simply update and uncomment "imageRegistry": "\<myrepo\>"*
```
~$ ~/google-cloud-sdk/bin/skaffold config set default-repo <myrepo>
```

* It takes a minute or so for the fabric minecraft server to download the mods and start, so expect the voyager pod to throw "RuntimeError: Minecraft server reply with code 400" until the minecraft server is available.

* If you run into an issue with loading your own (Non GPT-4/text-embedding-ada-002) based skills library, double check the settings in k8s/voyager-deploy.yaml for RESUME_SKILL_LIBRARY.  There you can also view/change the directories used for both "SKILL_LIBRARY_DIR" and "YOUR_CKPT_DIR".  I've actually not been able to resume my own skills library, primarly due to tasks not successfully completing, but when restarting deployments you may see issues around either "FileNotFoundError: [Errno 2] No such file or directory: '.../curriculum/qa_cache.json'" or vector store ([chromadb](https://www.trychroma.com/)] related and the "Curriculum Agent's qa cache question vectordb is not synced with qa_cache.json", with a recommendation "You may need to manually delete the qa cache question vectordb directory for running from scratch".

### Manual/CLI Build with Docker
```
~$ export SKAFFOLD_DEFAULT_REPO=<myrepo>
~$ docker build -t ${SKAFFOLD_DEFAULT_REPO}/voyager -f services/voyager.Dockerfile .
~$ docker push ${SKAFFOLD_DEFAULT_REPO}/voyager:latest

~$ docker build -t ${SKAFFOLD_DEFAULT_REPO}/voyager-dev -f services/Dockerfile .
~$ docker push ${SKAFFOLD_DEFAULT_REPO}/voyager-dev:latest
```

### Manual/CLI Deployment with Skaffold
```
~$ SKAFFOLD_DEFAULT_REPO=<myrepo> ~/google-cloud-sdk/bin/skaffold dev -v debug --port-forward --rpc-http-port 42535 --filename skaffold.yaml
```
