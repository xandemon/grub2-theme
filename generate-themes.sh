#!/bin/bash

# Script to generate GRUB theme variants from base theme and variant images
# Usage: ./generate-themes.sh

set -e  # Exit on error

BASE_DIR="base"
VARIANTS_DIR="variants"
THEMES_DIR="themes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating GRUB theme variants...${NC}\n"

# Check if base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}Error: Base directory '$BASE_DIR' not found!${NC}"
    exit 1
fi

# Check if variants directory exists
if [ ! -d "$VARIANTS_DIR" ]; then
    echo -e "${RED}Error: Variants directory '$VARIANTS_DIR' not found!${NC}"
    exit 1
fi

# Create themes directory if it doesn't exist
mkdir -p "$THEMES_DIR"

# Get list of image files in variants directory
variant_images=$(find "$VARIANTS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

if [ -z "$variant_images" ]; then
    echo -e "${YELLOW}Warning: No image files found in '$VARIANTS_DIR' directory!${NC}"
    # Clean up all themes if no variants exist
    if [ -d "$THEMES_DIR" ] && [ -n "$(ls -A "$THEMES_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}Removing all themes as no variants exist...${NC}"
        rm -rf "$THEMES_DIR"/*
    fi
    exit 0
fi

# Collect variant names for cleanup check
declare -a current_variant_names

# Process each variant image
for variant_path in $variant_images; do
    # Get filename without extension for theme name
    variant_filename=$(basename "$variant_path")
    variant_name="${variant_filename%.*}"
    variant_ext="${variant_filename##*.}"
    
    # Track this variant name
    current_variant_names+=("$variant_name")
    
    echo -e "${GREEN}Processing variant: ${BLUE}$variant_name${NC}"
    
    # Create theme directory
    theme_dir="$THEMES_DIR/$variant_name"
    mkdir -p "$theme_dir"
    
    # Copy all files from base directory to theme directory
    echo -e "  ${YELLOW}→${NC} Copying base assets..."
    cp -r "$BASE_DIR"/* "$theme_dir/"
    
    # Copy variant image to theme directory
    echo -e "  ${YELLOW}→${NC} Copying variant image..."
    cp "$variant_path" "$theme_dir/"
    
    # Update theme.txt to use the variant image
    theme_txt="$theme_dir/theme.txt"
    if [ -f "$theme_txt" ]; then
        echo -e "  ${YELLOW}→${NC} Updating theme.txt..."
        # Use sed to replace desktop-image line
        sed -i "s|desktop-image: \".*\"|desktop-image: \"$variant_filename\"|" "$theme_txt"
        echo -e "  ${GREEN}✓${NC} Theme '$variant_name' generated successfully!"
    else
        echo -e "  ${RED}✗${NC} Error: theme.txt not found in base directory!"
        exit 1
    fi
    
    echo ""
done

# Clean up orphaned themes (themes without corresponding variants)
if [ -d "$THEMES_DIR" ]; then
    echo -e "${BLUE}Checking for orphaned themes...${NC}"
    for theme_dir in "$THEMES_DIR"/*; do
        if [ -d "$theme_dir" ]; then
            theme_name=$(basename "$theme_dir")
            # Check if this theme corresponds to a current variant
            found=false
            for variant_name in "${current_variant_names[@]}"; do
                if [ "$theme_name" = "$variant_name" ]; then
                    found=true
                    break
                fi
            done
            
            if [ "$found" = false ]; then
                echo -e "  ${YELLOW}→${NC} Removing orphaned theme: ${BLUE}$theme_name${NC}"
                rm -rf "$theme_dir"
            fi
        fi
    done
fi

echo ""
echo -e "${GREEN}All themes generated successfully!${NC}"
echo -e "${BLUE}Themes are available in: ${THEMES_DIR}/${NC}"
