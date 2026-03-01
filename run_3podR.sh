#!/bin/bash

# --- 1. CHECK FOR DOCKER INSTALLATION ---
if ! [ -x "$(command -v docker)" ]; then
    echo "🚀 Docker not found. Detecting OS for installation..."
    OS_TYPE="$(uname -s)"

    if [[ "$OS_TYPE" == "Darwin" ]]; then
        echo "🍎 Mac detected. Checking for Homebrew..."
        
        if ! [ -x "$(command -v brew)" ]; then
            echo "🍺 Homebrew not found. Installing Homebrew..."
            # NONINTERACTIVE=1 ensures the script doesn't pause for user confirmation
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" <<EOF
          
EOF
            # Load brew into the current shell session path
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi

        echo "📦 Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        open /Applications/Docker.app

    elif [[ "$OS_TYPE" == *"NT"* || "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS" ]]; then
        echo "🪟 Windows detected. Using winget..."
        
        if command -v winget.exe >/dev/null 2>&1; then
            echo "📦 Installing Docker Desktop via winget..."
            winget.exe install --id Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements
            
            echo "🚀 Starting Docker Desktop..."
            # Use the default installation path for Windows
            "/c/Program Files/Docker/Docker/Docker Desktop.exe" & 
        else
            echo "❌ winget not found. Please install Docker manually: https://www.docker.com"
            exit 1
        fi
    else
        echo "❌ Unsupported OS."
        exit 1
    fi
fi

# --- 2. WAIT FOR DOCKER ENGINE ---
echo "🐋 Waiting for Docker engine to start..."
MAX_RETRIES=60 
COUNT=0
until docker info >/dev/null 2>&1; do
    echo "  ...still waiting (attempt $COUNT/60)..."
    sleep 10
    ((COUNT++))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "⏱️ Timeout: Docker engine didn't start. If this is a fresh install, a RESTART may be required."
        exit 1
    fi
done
echo "✅ Docker engine is ready!"

# --- 3. PREPARE LOCAL ENVIRONMENT ---
mkdir -p results

# --- 4. PULL AND RUN ---
echo "📥 Pulling latest container..."
docker pull cdrl/3podr_container:latest

echo "📊 Running 3PodR Report..."
# Using $(pwd) with Windows path translation logic
docker run --rm \
  -e R_LIBS_USER=/opt/renv/library \
  -e R_PROFILE_USER=/dev/null \
  -v "$(pwd)":/project \
  -v "$(pwd)/results":/project/results \
  --entrypoint R \
  cdrl/3podr_container:latest \
  -e 'bookdown::render_book("index.Rmd", output_dir = "results"); if(exists("global_state")) saveRDS(global_state, "results/global_state.RDS")'

echo "✅ Done! Check the 'results' folder."

