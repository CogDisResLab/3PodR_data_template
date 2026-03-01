#!/bin/bash

# --- 1. CHECK FOR DOCKER INSTALLATION ---
if ! [ -x "$(command -v docker)" ]; then
    echo "🚀 Docker not found. Detecting OS for installation..."
    OS_TYPE="$(uname -s)"

    if [[ "$OS_TYPE" == "Darwin" ]]; then
        echo "🍎 Mac detected. Downloading Docker Desktop..."
        ARCH=$( [ "$(uname -m)" == "arm64" ] && echo "arm64" || echo "amd64" )
        curl -L -o Docker.dmg "https://desktop.docker.com/mac/main/$ARCH/Docker.dmg"
        echo "📦 Installing Docker... (this may require your Mac password)"
        sudo hdiutil attach Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
        sudo hdiutil detach /Volumes/Docker
        rm Docker.dmg
        open /Applications/Docker.app
    elif [[ "$OS_TYPE" == *"NT"* || "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS" ]]; then
        echo "🪟 Windows detected. Downloading Docker Desktop Installer..."
        curl -L -o DockerInstaller.exe "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        echo "📦 Launching Installer... Please complete the setup and restart this terminal."
        ./DockerInstaller.exe
        exit 0
    else
        echo "❌ Unsupported OS. Please install Docker manually: https://www.docker.com"
        exit 1
    fi
fi

# --- 2. WAIT FOR DOCKER ENGINE ---
echo "🐋 Waiting for Docker engine to start..."
until docker info >/dev/null 2>&1; do
  echo "  ...still waiting (make sure Docker Desktop is open)..."
  sleep 5
done
echo "✅ Docker engine is ready!"

# --- 3. PREPARE LOCAL ENVIRONMENT ---
mkdir -p results

# --- 4. PULL AND RUN ---
echo "📥 Pulling latest container..."
docker pull cdrl/3podr_container:latest



echo "📊 Running 3PodR Report..."
docker run --rm \
  -e R_LIBS_USER=/opt/renv/library \
  -e R_PROFILE_USER=/dev/null \
  -v "$(pwd)/extdata":/project/extdata \
  -v "$(pwd)/configuration.yml":/project/configuration.yml \
  -v "$(pwd)/results":/project/results \
  --entrypoint R \
  cdrl/3podr_container:latest \
  -e 'bookdown::render_book("index.Rmd", output_dir = "results"); if(exists("global_state")) saveRDS(global_state, "results/global_state.RDS")'

echo "✅ Done! Check the 'results' folder for your output."
