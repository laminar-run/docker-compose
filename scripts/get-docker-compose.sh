command_present() {
  type "$1" >/dev/null 2>&1
}

if ! command_present docker-compose; then
  echo "Docker-compose is not installed. Installing now..."
else
  echo "Docker-compose is already installed. Skipping installation."
  exit 0
fi

sudo -E curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose