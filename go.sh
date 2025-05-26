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
echo -n "Select project to activate (1-${#projects[@]}), 'n' to create new project, or 'c' to clear all volumes: "
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
    
    # Update docker-compose.yml with selected project
    sed -i.bak "s|./projects/[^:]*:/project|./projects/$selected_project:/project|" compose.yml
    
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

# Update docker-compose.yml with selected project
sed -i.bak "s|./projects/[^:]*:/project|./projects/$selected_project:/project|" compose.yml

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