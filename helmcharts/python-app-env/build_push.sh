docker login

# Verificar o usuario que logou:

USUARIO=$(jq -r '.auths."https://index.docker.io/v1/".auth' ~/.docker/config.json | base64 --decode | cut -d: -f1)
echo $USUARIO

# Nome da imagem (ajuste para seu próprio repositório)
docker build -t $USUARIO/python-env-app:latest .

# Login no DockerHub ou outro registry (ex: Azure Container Registry)
docker push $USUARIO/flask-env-app:latest
