# take image
docker run --name internal_registry -d -p 5000:5000 samalba/docker-registry
# sudo -i (need root)
# add hosts
echo "127.0.0.1      internal_registry" >> /etc/hosts
# install curl
apt-get install -y curl
# test connect
curl --get --verbose http://internal_registry:5000/v1/_ping
