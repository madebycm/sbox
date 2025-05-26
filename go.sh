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
echo -n "Select project to activate (1-${#projects[@]}): "
read selection

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#projects[@]} ]; then
    echo "Invalid selection"
    exit 1
fi

# Get selected project
selected_project="${projects[$((selection-1))]}"
echo "Activating project: $selected_project"

# Update docker-compose.yml with selected project
sed -i.bak "s|./projects/[^:]*:/project|./projects/$selected_project:/project|" docker-compose.yml

# Check if container exists
if [ "$(docker ps -aq -f name=persistent-ubuntu-dev)" ]; then
    # Container exists, recreate with new mount
    docker-compose down
    docker-compose up -d
    docker-compose exec ubuntu-dev /bin/bash
else
    # First run, build and start
    docker-compose up -d --build
    docker-compose exec ubuntu-dev /bin/bash
fi