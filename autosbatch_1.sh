#!/bin/bash

#####################################
# Authors: Michele Loriso, Manuel Pasquetti, Francesco Ambrosio
# Version: v1.0.0
# Date: 20-05-2025
# Description: Autosbatcher for CP2K
# Usage: ./autosbatch.sh 
# Provide at least a "*job*" file, a "*.inp" file and one or more "*.xyz" files.
#####################################

XYZ_PLACEHOLDER="XYZ_NAME"
UKS_PLACEHOLDER="UKS"
CHARGE_PLACEHOLDER="CHARGE"
PROJECT_PLACEHOLDER="PROJECT_NAME"
JOB_INP_PLACEHOLDER="INFILE"
JOB_OUT_PLACEHOLDER="OUTFILE"
shopt -s nullglob
xyz_files_list=( *.xyz )
inp_files_list=( *.inp )
job_files_list=( *job* )

# 1) Scanning the current directory and checking for a generic input file, a generic job-file and for .xyz files
if [ ${#xyz_files_list[@]} -eq 0 ]; then
	echo "No .xyz files found. Aborting."
	exit 1
fi
if [ ${#inp_files_list[@]} -ne 1 ]; then
	echo "No .inp file or too many .inp files found. Aborting."
	exit 1
fi
if [ ${#job_files_list[@]} -ne 1 ]; then
	echo "No job file or too many job files found. Aborting."
	exit 1
fi

# 3) For each .xyz file:
for file in "${xyz_files_list[@]}"; do
	# 3.1) make a directory with the same name, move the .xyz file into it and copy the job file and the input file;
	echo "Processing file: $file"
	echo
	base_name="${file%.*}"
	mkdir -p "$base_name"
	cp "$file" "${job_files_list[0]}" "${inp_files_list[0]}" "$base_name"
	# 3.2) cd into the directory, rename files and populate fields in both the input file and the job-file
	cd "$base_name" || exit 1
	mv "${job_files_list[0]}" "job-${base_name}"
	mv "${inp_files_list[0]}" "${base_name}.inp"
	# 3.3) manage placeholders in the job file
	sed -i "s|${JOB_INP_PLACEHOLDER}|${base_name}.inp|g" "job-${base_name}"
	sed -i "s|${JOB_OUT_PLACEHOLDER}|${base_name}.out|g" "job-${base_name}"
	# 3.4) manage placeholders in the .inp file
		# 3.4.1) check for radicals and/or charges
	if [[ "$base_name" == *anion* ]]; then
		sed -i "s|${CHARGE_PLACEHOLDER}|CHARGE -1|g" "${base_name}.inp"
	elif [[ "$base_name" == *cation* ]]; then
		sed -i "s|${CHARGE_PLACEHOLDER}|CHARGE +1|g" "${base_name}.inp"
	else
		sed -i "s|${CHARGE_PLACEHOLDER}|!CHARGE|g" "${base_name}.inp"
	fi
	if [[ "$base_name" == *rad* ]]; then
		sed -i "s|${UKS_PLACEHOLDER}|UKS T|g" "${base_name}.inp"
	else
		sed -i "s|${UKS_PLACEHOLDER}|!UKS|g" "${base_name}.inp"
	fi
	sed -i "s|${XYZ_PLACEHOLDER}|$file|g" "${base_name}.inp"
	sed -i "s|${PROJECT_PLACEHOLDER}|${base_name}-proj|g" "${base_name}.inp"
	# 3.4) sbatch the job and cd ..
	sbatch "job-${base_name}"
	cd .. || exit 1
done
