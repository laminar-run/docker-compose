command_present() {
  type "$1" >/dev/null 2>&1
}

if ! command_present docker; then
  echo "Docker is not installed. Installing now..."
else
  echo "Docker is already installed. Skipping installation."
  exit 0
fi

if ! command_present apt-get && command_present yum; then
  sudo amazon-linux-extras install docker -y
  sudo service docker start
  sudo usermod -a -G docker [user]
else
  wget -qO- https://get.docker.com/ | sh
  sudo usermod -aG docker $USER
  newgrp docker
fi