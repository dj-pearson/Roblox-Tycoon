#!/usr/bin/env python
"""
Roblox Model Renamer

This script looks into all folders within the Workspace > GymParts folder
and appends '_Big' to filenames for models with a scale less than 1.

Usage:
    python rename_small_models.py [--dry-run]

Arguments:
    --dry-run   Only print actions without making changes
"""

import os
import sys
import argparse
import xml.etree.ElementTree as ET
import glob
import re

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Rename Roblox model files based on scale'
    )
    parser.add_argument('--dry-run', action='store_true', 
                        help='Only print changes without renaming files')
    return parser.parse_args()

def get_model_scale(model_file):
    """Extract the scale of a model from its .rbxm file."""
    try:
        # For XML format (.rbxmx)
        if model_file.lower().endswith('.rbxmx'):
            tree = ET.parse(model_file)
            root = tree.getroot()
            # Look for scale properties in the XML
            for prop in root.findall(".//Properties/float3[@name='Size']"):
                # Parse X, Y, Z values (simplified - actual implementation might need refinement)
                values = prop.text.split(',')
                if len(values) >= 3:
                    x, y, z = float(values[0]), float(values[1]), float(values[2])
                    # Calculate average scale - this is a simplification
                    return (x + y + z) / 3
            
            # If we couldn't find Size, check for Scale property
            for prop in root.findall(".//Properties/float[@name='Scale']"):
                return float(prop.text)
                
            # Default scale if not found
            return 1.0
            
        # For binary format (.rbxm)
        else:
            # Binary parsing is more complex and might require a dedicated library
            # For this example, we'll assume binary models are at default scale
            print(f"Warning: Binary model format (.rbxm) in {model_file} - scale detection not supported")
            return 1.0
            
    except Exception as e:
        print(f"Error reading model file {model_file}: {e}")
        return 1.0

def process_models(dry_run=False):
    """Process all model files in the GymParts folder."""
    # Base path to look for models - adjust as needed based on your project structure
    base_path = os.path.join(os.getcwd(), "src", "Workspace", "GymParts")
    
    if not os.path.exists(base_path):
        print(f"Error: GymParts folder not found at {base_path}")
        print("Make sure you're running this script from the project root directory")
        return
    
    # Find all model files
    model_files = []
    for ext in ['.rbxm', '.rbxmx']:
        model_files.extend(glob.glob(os.path.join(base_path, "**", f"*{ext}"), recursive=True))
    
    if not model_files:
        print("No model files found in GymParts folders")
        return
    
    renamed_count = 0
    
    for model_file in model_files:
        scale = get_model_scale(model_file)
        
        # Check if scale is less than 1.0
        if scale < 1.0:
            filename = os.path.basename(model_file)
            directory = os.path.dirname(model_file)
            
            # Check if filename already has _Big suffix
            name_parts = os.path.splitext(filename)
            if not name_parts[0].endswith('_Big'):
                new_filename = f"{name_parts[0]}_Big{name_parts[1]}"
                new_filepath = os.path.join(directory, new_filename)
                
                if dry_run:
                    print(f"Would rename: {filename} -> {new_filename} (Scale: {scale:.2f})")
                else:
                    try:
                        os.rename(model_file, new_filepath)
                        print(f"Renamed: {filename} -> {new_filename} (Scale: {scale:.2f})")
                        renamed_count += 1
                    except Exception as e:
                        print(f"Error renaming {filename}: {e}")
    
    action = "Would rename" if dry_run else "Renamed"
    print(f"\n{action} {renamed_count} files")

if __name__ == "__main__":
    args = parse_arguments()
    process_models(args.dry_run)
