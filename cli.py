#!/usr/bin/env python3
# @author madebycm (2025-01-26)

import os
import sys
from blessed import Terminal
from sandbox_manager import SandboxManager

class SandboxCLI:
    def __init__(self):
        self.term = Terminal()
        self.manager = SandboxManager()
        self.selected = 0
        self.sandboxes = []
        
    def refresh_sandboxes(self):
        self.sandboxes = self.manager.list_sandboxes()
        
    def draw_menu(self):
        print(self.term.clear())
        print(self.term.bold("🐳 Docker Sandbox Manager"))
        print("─" * 40)
        
        if not self.sandboxes:
            print("\nNo sandboxes found.")
        else:
            print("\nExisting sandboxes:")
            for i, sandbox in enumerate(self.sandboxes):
                if i == self.selected:
                    print(f"{self.term.reverse} → {sandbox} ")
                else:
                    print(f"   {sandbox}")
        
        print("\n" + "─" * 40)
        print("Commands:")
        print("[↑/↓] Navigate  [Enter] Connect  [n] New")
        print("[d] Delete      [c] Clean All   [q] Quit")
        
    def create_sandbox(self):
        # Exit fullscreen mode temporarily for input
        print(self.term.normal_screen)
        name = input("Enter sandbox name: ")
        if name and name not in self.sandboxes:
            print("Creating sandbox...")
            self.manager.create_sandbox(name)
            self.refresh_sandboxes()
        # Return to fullscreen mode
        print(self.term.enter_fullscreen)
                
    def connect_sandbox(self):
        if self.sandboxes and 0 <= self.selected < len(self.sandboxes):
            sandbox_name = self.sandboxes[self.selected]
            print(self.term.clear())
            print(f"Connecting to {sandbox_name}...")
            self.manager.connect_to_sandbox(sandbox_name)
            
    def delete_sandbox(self):
        if self.sandboxes and 0 <= self.selected < len(self.sandboxes):
            sandbox_name = self.sandboxes[self.selected]
            # Exit fullscreen mode temporarily for input
            print(self.term.normal_screen)
            confirm = input(f"Delete {sandbox_name}? (y/N): ")
            if confirm.lower() == 'y':
                print("Deleting sandbox...")
                self.manager.delete_sandbox(sandbox_name)
                self.refresh_sandboxes()
                if self.selected >= len(self.sandboxes) and self.selected > 0:
                    self.selected = len(self.sandboxes) - 1
            # Return to fullscreen mode
            print(self.term.enter_fullscreen)
            
    def clean_all(self):
        """Clean all sandboxes and persistent data"""
        # Exit fullscreen mode temporarily for input
        print(self.term.normal_screen)
        confirm = input("⚠️  This will DELETE ALL sandboxes and persistent data. Are you sure? (yes/N): ")
        if confirm.lower() == 'yes':
            print("Cleaning all sandboxes and persistent data...")
            if self.manager.clean_all():
                print("✓ All data cleaned successfully")
                self.sandboxes = []
                self.selected = 0
            else:
                print("✗ Failed to clean all data")
            input("\nPress Enter to continue...")
        # Return to fullscreen mode
        print(self.term.enter_fullscreen)
                    
    def run(self):
        self.refresh_sandboxes()
        
        with self.term.fullscreen(), self.term.cbreak():
            while True:
                self.draw_menu()
                
                key = self.term.inkey()
                
                if key.name == 'KEY_UP' and self.selected > 0:
                    self.selected -= 1
                elif key.name == 'KEY_DOWN' and self.selected < len(self.sandboxes) - 1:
                    self.selected += 1
                elif key.name == 'KEY_ENTER':
                    self.connect_sandbox()
                    self.refresh_sandboxes()
                elif key.lower() == 'n':
                    self.create_sandbox()
                elif key.lower() == 'd':
                    self.delete_sandbox()
                elif key.lower() == 'c':
                    self.clean_all()
                elif key.lower() == 'q':
                    break
                    
if __name__ == "__main__":
    cli = SandboxCLI()
    cli.run()