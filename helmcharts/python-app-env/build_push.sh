echo ""
docker login
echo ""
# Verificar o usuario que logou:

USUARIO=$(jq -r '.auths."https://index.docker.io/v1/".auth' ~/.docker/config.json | base64 --decode | cut -d: -f1)
echo $USUARIO

# Nome da imagem (ajuste para seu próprio repositório)
docker build -t $USUARIO/python-env-app:latest .

docker build -f Dockerfile.win -t $USUARIO/python-env-app:win .

# Login no DockerHub ou outro registry (ex: Azure Container Registry)
echo ""
echo "Caso queira publicar a imagem no Docker Hub, executar o comando abaixo:"
echo "              docker push $USUARIO/python-env-app:latest"
echo ""
echo "Caso queira rodar o Conteiner, executar o comando abaixo:"
echo "              docker run -e chave2="oi mundo" -e chave1="chave 1 definida com -e" --name env --rm -p 32000:5000 -d tonanuvem/python-env-app:latest"
echo ""
