#!/usr/bin/env python3
# @author madebycm (2025-01-26)

import docker
import time
import sys

def test_shared_installation():
    client = docker.from_env()
    
    print("=== Testing Shared Package Installation ===\n")
    
    # Get the persistent container
    try:
        container = client.containers.get('sandbox-persistent')
    except docker.errors.NotFound:
        print("Error: Persistent container not found. Run ./sandbox first.")
        return False
    
    # Clean up any existing test sandboxes
    print("1. Cleaning up existing test sandboxes...")
    container.exec_run("rm -rf /sandboxes/test1 /sandboxes/test2", user='root')
    
    # Create first sandbox
    print("\n2. Creating first sandbox (test1)...")
    container.exec_run("mkdir -p /sandboxes/test1", user='root')
    container.exec_run("chown -R sandbox:users /sandboxes/test1", user='root')
    
    # Install htop in first sandbox context
    print("\n3. Installing htop...")
    exit_code, output = container.exec_run(
        "bash -c 'cd /sandboxes/test1 && apt-get update -qq && apt-get install -y htop'",
        user='root',
        workdir='/sandboxes/test1'
    )
    
    if exit_code == 0:
        print("   ✓ htop installed successfully")
    else:
        print(f"   ✗ Failed to install htop: {output.decode()}")
        return False
    
    # Create second sandbox
    print("\n4. Creating second sandbox (test2)...")
    container.exec_run("mkdir -p /sandboxes/test2", user='root')
    container.exec_run("chown -R sandbox:users /sandboxes/test2", user='root')
    
    # Check if htop is available in second sandbox
    print("\n5. Checking if htop is available in second sandbox...")
    exit_code, output = container.exec_run(
        "which htop",
        user='sandbox',
        workdir='/sandboxes/test2'
    )
    
    if exit_code == 0 and '/usr/bin/htop' in output.decode():
        print("   ✓ SUCCESS: htop is available in sandbox test2!")
        print(f"   htop location: {output.decode().strip()}")
        
        # Run htop version to confirm it works
        exit_code, output = container.exec_run("htop --version", user='sandbox')
        print(f"   htop version: {output.decode().strip()}")
        result = True
    else:
        print("   ✗ FAILED: htop is NOT available in sandbox test2")
        result = False
    
    # Cleanup
    print("\n6. Cleaning up test sandboxes...")
    container.exec_run("rm -rf /sandboxes/test1 /sandboxes/test2", user='root')
    
    print("\n=== Test Complete ===")
    return result

if __name__ == "__main__":
    success = test_shared_installation()
    sys.exit(0 if success else 1)