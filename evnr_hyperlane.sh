#!/bin/bash

# Define colors
RED='\033[0;31m'
NC='\033[0m'

# Display ASCII Art
display_ascii() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Installing curl...${NC}"
        sudo apt update
        sudo apt install curl -y
    fi
    sleep 1
    curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/main/evenorlogo.sh | bash
}

# Install Node
install_node() {
    echo -e "${RED}Installing Hyperlane node...${NC}"
    echo -e "Updating system..."
    sudo apt update -y
    sudo apt upgrade -y

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo -e "Installing Docker..."
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo -e "Docker is already installed"
    fi

    echo -e "Pulling Docker image..."
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

    echo -e "Enter validator name:"
    read NAME
    echo -e "Enter your EVM private key (starting with 0x):"
    read PRIVATE_KEY

    mkdir -p $HOME/hyperlane_db_base
    chmod -R 777 $HOME/hyperlane_db_base

    echo -e "Starting Docker container..."
    docker run -d -it \
    --name hyperlane \
    --mount type=bind,source=$HOME/hyperlane_db_base,target=/hyperlane_db_base \
    gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
    ./validator \
    --db /hyperlane_db_base \
    --originChainName base \
    --reorgPeriod 1 \
    --validator.id "$NAME" \
    --checkpointSyncer.type localStorage \
    --checkpointSyncer.folder base \
    --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
    --validator.key "$PRIVATE_KEY" \
    --chains.base.signer.key "$PRIVATE_KEY" \
    --chains.base.customRpcUrls https://base.llamarpc.com

    echo -e "Node successfully installed!"
    echo -e "To view logs, use: docker logs -f hyperlane"
    echo -e "script by evenor.eth"
    echo -e "Displaying logs..."
    sleep 2
    docker logs -f hyperlane
}

# View Logs
view_logs() {
    echo -e "${RED}Viewing logs...${NC}"
    docker logs -f hyperlane
    echo -e "script by evenor.eth"
}

# Remove Node
remove_node() {
    echo -e "${RED}Removing Hyperlane node...${NC}"
    echo -e "Stopping and removing container..."
    docker stop hyperlane
    docker rm hyperlane

    if [ -d "$HOME/hyperlane_db_base" ]; then
        echo -e "Removing node directory..."
        rm -rf $HOME/hyperlane_db_base
        echo -e "Node directory removed"
    fi

    echo -e "Node successfully removed!"
    echo -e "script by evenor.eth"
}

# Main Menu
main_menu() {
    while true; do
        display_ascii
        echo -e "script by evenor.eth"
        echo -e "1) Install Node"
        echo -e "2) View Logs"
        echo -e "3) Remove Node"
        echo -e "4) Exit"
        read -p "Select an option [1-4]: " choice

        case $choice in
            1) install_node ;;
            2) view_logs ;;
            3) remove_node ;;
            4) echo -e "Exiting..."; exit 0 ;;
            *) echo -e "Invalid selection. Use numbers 1 to 4." ;;
        esac

        if [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ]; then
            read -p "Press Enter to return to the menu..."
        fi
    done
}

# Start script
main_menu
