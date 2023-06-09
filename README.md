**Prerequirments**
- Account in docker hub https://hub.docker.com
- Username for the docker hub account
- Email address used for the docker hub account
- Personal Access Token (PAT) for accessing the docker hub account. If you dont have a PAT, refer to https://docs.docker.com/docker-hub/access-tokens/


**Configure Docker Login through Cli**

- Change to your $HOME directory
```bash
cd $HOME
```
- Make **.docker** folder (if not already present)
```bash
mkdir .docker
```
- Create a **config.json** file (if not already present) in **.docker** folder
```bash
vi .docker/config.json
```
- The content of the **config.json** file should be as follows:
```bash
{
    "auths": {
      "https://index.docker.io/v1/": {
        "auth": "<Base64 encoded PAT for docker hub>",
        "email": "dummy@dummy.com"
      }
    }
  }
```
- If your PAT is e.g **Abcdefgh**, then the output of the following command will be your base64 encoded PAT for docker hub
```bash
echo "Abcdefgh" | base64
```
- Save the **config.json**, once the values have been configured

- Perform docker login on your terminal:
```bash
docker login
```

- You should see similar output on your terminal:
```bash
Login Succeeded
```

**Building images for cosmos exporter application**
- Clone the repository: https://github.com/Blockchain-Insight/Dockerfile
```bash
git clone git@github.com:Blockchain-Insight/Dockerfile.git
```
- Change to cosmos-exporter folder of the cloned repository
```bash
cd Dockerfile/cosmos-exporter
```
- Build docker image for cosmos-exporter from dockerfile with tag **dev**
```bash
docker build --tag <username>/cosmos-exporter:dev .
```
username: Username for the docker hub account

- You can look for the created image on terminal by:
```bash
docker images | grep cosmos-exporter
```
- Push the image to docker hub
```bash
docker push <username>/cosmos-exporter:dev
```

**Building images for full node application**
- Change to node folder of the cloned repository https://github.com/Blockchain-Insight/Dockerfile
```bash
cd Dockerfile/node
```
- Build docker image for full node from dockerfile with tag **dev**
```bash
docker build --tag <username>/full-node:dev .
```
username: Username for the docker hub account

- You can look for the created image on terminal by:
```bash
docker images | grep full-node
```
- Push the docker image to docker hub
```bash
docker push <username>/cosmos-exporter:dev
```

**Check images in docker hub console**
- Log in to your account in docker hub through browser
- Check for the pushed images **full-node** and **cosmos-exporter**
