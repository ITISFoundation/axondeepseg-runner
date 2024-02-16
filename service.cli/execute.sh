#!/bin/bash
# set sh strict mode
set -e
set -o errexit
set -o nounset
IFS=$(printf '\n\t')

cd /home/scu/
echo "starting service as"
echo   User    : "$(id "$(whoami)")"
echo   Workdir : "$(pwd)"
echo "..."
echo
# ----------------------------------------------------------------
# This script shall be modified according to the needs in order to run the service
# The inputs defined in ${INPUT_FOLDER}/inputs.json are available as env variables by their key in capital letters
# For example: input_1 -> $INPUT_1

# Copy input image
echo "Getting image from input_1..."
num_imagefile=$(find "${INPUT_FOLDER}" \( -type f -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.tif" -o -name "*.tiff" \) | wc -l)
#num_imagefile=$(find ${INPUT_FOLDER} -name '' .{png,jpeg,jpg,tif,tiff}" | wc -l)
if [ "$num_imagefile" = 1 ]; then
    filen="$(find "${INPUT_FOLDER}" \( -type f -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.tif" -o -name "*.tiff" \))"
    cp "$filen" .
    filen="$(basename "${filen}")"
else
    echo "Please provide only one image file"
    exit 1
fi

# Create an array of arguments

if [ $INPUT_7 = "Developer Mode" ]; then
    vlevel=1
else
    vlevel=0    
fi
args=(
-i "$filen"
-t "${INPUT_2//\"}"
-s "${INPUT_3}"
-v "${vlevel}"
--overlap "${INPUT_4}"
-z "${INPUT_5}"
--gpu-id 0
)
# Optional flags: if checked in the UI -> input is true -> add flag
if [ $INPUT_6 = true ]; then
    args+=(--no-patch)
fi

# Launch segmentation
echo "Starting segmentation with args ${args[@]}"
axondeepseg "${args[@]}"
echo "Segmentation completed successfully, adding it to first output..."
# Add segmented images to output already
zip -r "${OUTPUT_FOLDER}"/segmented_image.zip "${filen%%.*}_seg-axon.png" "${filen%%.*}_seg-axonmyelin.png" "${filen%%.*}_seg-myelin.png"

args=(
-i "$filen"
-s "${INPUT_3}"
-a "${INPUT_8//\"}"
-f "axon_morphometrics.csv"
)
if [ $INPUT_9 = true ]; then
    args+=(-b)
fi
echo "Starting morphometric extraction with args ${args[@]}..."
axondeepseg_morphometrics "${args[@]}"

# Add morphometrics to the outputs
echo "Extraction of morphometrics completed successfully, adding it to the second output..."
cp /home/scu/*axon_morphometrics.csv "${OUTPUT_FOLDER}"/axon_morphometrics.csv

