# @author madebycm (2025-01-26)

import os
import sys
import docker
import subprocess
from pathlib import Path

class SandboxManager:
    def __init__(self):
        self.client = docker.from_env()
        self.base_container = "sandbox-persistent"
        self.image_name = "sandbox-base:latest"
        self.ensure_base_image()
        self.ensure_persistent_container()
        
    def ensure_base_image(self):
        try:
            self.client.images.get(self.image_name)
        except docker.errors.ImageNotFound:
            print("Building base image...")
            self.client.images.build(
                path=".",
                tag=self.image_name,
                rm=True
            )
            
    def ensure_persistent_container(self):
        """Ensure the persistent container is running"""
        try:
            container = self.client.containers.get(self.base_container)
            if container.status != 'running':
                container.start()
        except docker.errors.NotFound:
            print("Creating persistent container...")
            container = self.client.containers.create(
                self.image_name,
                name=self.base_container,
                stdin_open=True,
                tty=True,
                detach=True,
                command="tail -f /dev/null"  # Keep container running
            )
            container.start()
            
            # Create sandboxes directory structure
            container.exec_run("mkdir -p /sandboxes", user='root')
            
    def list_sandboxes(self):
        """List all sandboxes by checking directories in persistent container"""
        container = self.client.containers.get(self.base_container)
        exit_code, output = container.exec_run("ls -1 /sandboxes 2>/dev/null || true", user='root')
        
        if exit_code == 0 and output:
            sandboxes = [s.strip() for s in output.decode().split('\n') if s.strip()]
            return sorted(sandboxes)
        return []
        
    def create_sandbox(self, name):
        """Create a new sandbox directory in the persistent container"""
        container = self.client.containers.get(self.base_container)
        
        # Create sandbox directory
        exit_code, output = container.exec_run(f"mkdir -p /sandboxes/{name}", user='root')
        
        if exit_code != 0:
            print(f"Error creating sandbox: {output.decode()}")
            return False
            
        # Set permissions
        container.exec_run(f"chown -R sandbox:users /sandboxes/{name}", user='root')
        return True
            
    def connect_to_sandbox(self, name):
        """Connect to a sandbox by executing bash in the persistent container with specific working directory"""
        container = self.client.containers.get(self.base_container)
        
        # Ensure sandbox exists
        exit_code, _ = container.exec_run(f"test -d /sandboxes/{name}", user='root')
        if exit_code != 0:
            print(f"Creating sandbox {name}...")
            self.create_sandbox(name)
            
        # Connect to the sandbox
        subprocess.run([
            'docker', 'exec', '-it', 
            '-w', f'/sandboxes/{name}',
            '-u', 'sandbox',
            '-e', f'PS1=\\u@{name}:\\w\\$ ',
            self.base_container, 
            '/bin/bash'
        ])
                
    def delete_sandbox(self, name):
        """Delete a sandbox directory from the persistent container"""
        container = self.client.containers.get(self.base_container)
        
        # Remove sandbox directory
        exit_code, output = container.exec_run(f"rm -rf /sandboxes/{name}", user='root')
        
        if exit_code != 0:
            print(f"Error deleting sandbox: {output.decode()}")
            return False
        return True
        
    def clean_all(self):
        """Remove all sandboxes and the persistent container"""
        try:
            # Stop and remove the persistent container
            container = self.client.containers.get(self.base_container)
            print("Stopping persistent container...")
            container.stop(timeout=5)
            print("Removing persistent container...")
            container.remove()
            
            # Remove any sandbox-* containers that might exist
            for container in self.client.containers.list(all=True):
                if container.name.startswith("sandbox-"):
                    try:
                        container.stop(timeout=2)
                        container.remove()
                    except:
                        pass
                        
            # Remove Docker volumes
            for volume in self.client.volumes.list():
                if volume.name == "sandbox-root-volume":
                    try:
                        volume.remove()
                    except:
                        pass
                        
            return True
        except Exception as e:
            print(f"Error during cleanup: {e}")
            return False