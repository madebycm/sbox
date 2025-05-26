#!/bin/bash
# @author madebycm (2025-01-26)

# Create projects directory if it doesn't exist
mkdir -p ./projects

# List available projects
echo "Available projects:"
projects=($(ls -d ./projects/*/ 2>/dev/null | xargs -n 1 basename))

if [ ${#projects[@]} -eq 0 ]; then
    echo "No projects found in ./projects/"
    echo "Create a folder in ./projects/ and run this script again."
    exit 1
fi

# Display projects with numbers
for i in "${!projects[@]}"; do
    echo "$((i+1)). ${projects[i]}"
done

# Get user selection
echo -n "Select project to activate (1-${#projects[@]}), 'n' to create new project, 'i' to install sbox command, or 'c' to clear all volumes: "
read selection

# Check if user wants to create new project
if [ "$selection" = "n" ] || [ "$selection" = "N" ]; then
    echo -n "Enter name for new project: "
    read project_name
    
    # Validate project name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Invalid project name. Use only letters, numbers, hyphens, and underscores."
        exit 1
    fi
    
    # Check if project already exists
    if [ -d "./projects/$project_name" ]; then
        echo "Project '$project_name' already exists."
        exit 1
    fi
    
    # Create new project directory
    mkdir -p "./projects/$project_name"
    echo "Created new project: $project_name"
    
    # Set as selected project
    selected_project="$project_name"
    echo "Activating project: $selected_project"
    
    # Export project path for docker-compose
    export PROJECT_PATH="./projects/$selected_project"
    
    # Check if container exists
    if [ "$(docker ps -aq -f name=persistent-sbox)" ]; then
        # Container exists, recreate with new mount
        docker-compose down
        docker-compose up -d
        docker-compose exec sbox /bin/bash
    else
        # First run, build and start
        docker-compose up -d --build
        docker-compose exec sbox /bin/bash
    fi
    exit 0
fi

# Check if user wants to install sbox command
if [ "$selection" = "i" ] || [ "$selection" = "I" ]; then
    echo "Installing sbox command..."
    
    # Get the absolute path to this sandbox directory
    SANDBOX_DIR="$(cd "$(dirname "$0")" && pwd)"
    
    # Create sbox script
    cat > "$SANDBOX_DIR/sbox" << 'EOF'
#!/bin/bash
# @author madebycm (2025-01-26)
# Sandbox launcher - mounts current directory as /project

# Get current directory
CURRENT_DIR="$(pwd)"

# Get sandbox directory from script location
SANDBOX_DIR="$(dirname "$(readlink -f "$0")")"

# Export project path for docker-compose
export PROJECT_PATH="$CURRENT_DIR"

# Change to sandbox directory
cd "$SANDBOX_DIR"

echo "Mounting $CURRENT_DIR as /project in sandbox..."

# Check if container exists
if [ "$(docker ps -aq -f name=persistent-sbox)" ]; then
    # Container exists, recreate with new mount
    docker-compose down
    docker-compose up -d
    docker-compose exec sbox /bin/bash
else
    # First run, build and start
    docker-compose up -d --build
    docker-compose exec sbox /bin/bash
fi
EOF
    
    # Make sbox executable
    chmod +x "$SANDBOX_DIR/sbox"
    
    # Always use .zprofile for PATH configuration
    SHELL_CONFIG="$HOME/.zprofile"
    
    # Check if sbox is already in PATH
    if ! grep -q "# Sandbox command" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Sandbox command" >> "$SHELL_CONFIG"
        echo "export PATH=\"$SANDBOX_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        echo "Added sbox to PATH in $SHELL_CONFIG"
        echo ""
        echo "Installation complete! To use sbox command:"
        echo "1. Reload your shell: source $SHELL_CONFIG"
        echo "2. Navigate to any directory and run: sbox"
    else
        echo "sbox command already installed in $SHELL_CONFIG"
    fi
    
    exit 0
fi

# Check if user wants to clear volumes
if [ "$selection" = "c" ] || [ "$selection" = "C" ]; then
    echo "WARNING: This will delete all Docker volumes and container data."
    echo -n "Type 'yes' to confirm: "
    read confirmation
    
    if [ "$confirmation" = "yes" ]; then
        echo "Clearing all Docker volumes..."
        docker-compose down -v
        echo "All volumes cleared. Container and data removed."
    else
        echo "Operation cancelled."
    fi
    exit 0
fi

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#projects[@]} ]; then
    echo "Invalid selection"
    exit 1
fi

# Get selected project
selected_project="${projects[$((selection-1))]}"
echo "Activating project: $selected_project"

# Export project path for docker-compose
export PROJECT_PATH="./projects/$selected_project"

# Check if container exists
if [ "$(docker ps -aq -f name=persistent-sbox)" ]; then
    # Container exists, recreate with new mount
    docker-compose down
    docker-compose up -d
    docker-compose exec sbox /bin/bash
else
    # First run, build and start
    docker-compose up -d --build
    docker-compose exec sbox /bin/bash
fi