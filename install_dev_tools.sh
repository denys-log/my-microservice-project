#!/bin/bash

echo "Starting installation of tools..."

echo "Updating system..."
sudo apt update

# Check and install Docker
if command -v docker &> /dev/null; then
    echo "Docker is already installed"
else
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "Docker installed"
fi

# Check and install Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "Docker Compose is already installed"
else
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose
    echo "Docker Compose installed"
fi

# Check and install Python
if command -v python3 &> /dev/null; then
    echo "Python is already installed"
else
    echo "Installing Python..."
    sudo apt install -y python3 python3-pip
    echo "Python installed"
fi

# Install pip if not present
if ! command -v pip3 &> /dev/null; then
    echo "Installing pip..."
    sudo apt install -y python3-pip
fi

# Check and install Django
if python3 -c "import django" &> /dev/null; then
    echo "Django is already installed"
else
    echo "Installing Django..."
    pip3 install django
    echo "Django installed"
fi

echo "Installation completed!"

# Check versions
echo "Checking installed versions:"
docker --version
docker-compose --version
python3 --version
python3 -c "import django; print('Django', django.get_version())"

echo "Done!"
