#!/bin/bash

#######################################################################################################
# Authors: Michele Loriso, Manuel Pasquetti, Francesco Ambrosio
# Version: v1.0.0
# Date: 20-05-2025
# Description: Autosbatcher for CP2K
# Usage: ./autosbatch_2.sh 
# Provide at least a "*job*" file, a "*.inp" file and one or more folders containing "*-proj-pos-1.xyz" files.
# -> For each molecule, three opts will be sbatched (2 GEO_OPTs for its anion and cation form and 1 WFN_OPT for the neutral form).
#######################################################################################################

XYZ_PLACEHOLDER="XYZ_NAME"
RESTART_PLACEHOLDER="WFN_RESTART_FILE_NAME"
MO_CUBES_PLACEHOLDER="PRINT_CUBES"
UKS_PLACEHOLDER="UKS"
CHARGE_PLACEHOLDER="CHARGE"
PROJECT_PLACEHOLDER="PROJECT_NAME"
JOB_INP_PLACEHOLDER="INFILE"
JOB_OUT_PLACEHOLDER="OUTFILE"
inp_files_list=( *.inp )
job_files_list=( *job* )

shopt -s nullglob

#1) Scanning the current directory and checking for any job and input files.

if [ ${#inp_files_list[@]} -ne 1 ]; then
	echo "No .inp file or too many .inp files found. Aborting."
	exit 1
fi
if [ ${#job_files_list[@]} -ne 1 ]; then
	echo "No job file or too many job files found. Aborting."
	exit 1
fi

#2) For each directory, look for "*pos-1.xyz"

for dir in */; do
	WFN_FOUND=0
	cd "$dir" || exit 1
	xyz_files_list=( *-pos-1.xyz )

	if [ ${#xyz_files_list[@]} -eq 0 ]; then
		echo "No .xyz file found in ${dir}. Aborting processing of ${dir}."
		cd ..
		continue
	fi

	if [ ${#xyz_files_list[@]} -gt 1 ]; then
		echo "Too many .xyz file found in ${dir}. Aborting processing of ${dir}."
		cd ..
		continue
	fi
	
	lines_in_file=$(wc -l < $xyz_files_list)
	
	if [ $lines_in_file -eq 0 ]; then
		echo "${xyz_files_list} is empty. Aborting processing of ${dir}."
		cd ..
		continue
	fi
	
	atoms_number=$(head -n 1 $xyz_files_list)

	if [[ "$atoms_number" =~ ^[0-9]+$ ]]; then
		:
	else
		echo "Invalid string in the first line of ${xyz_files_list}. Aborting processing of ${dir}."
		cd ..
		continue
	fi

	no_lines_to_copy=$((atoms_number+3))
	
	if [ $lines_in_file -lt $atoms_number ]; then
		echo "Syntax error in ${xyz_file}. Aborting processing of ${dir}."
		cd ..
		continue
	fi

	lines_to_copy=$(tail -n $no_lines_to_copy $xyz_files_list)

	#3) If one *-pos-1.xyz" file is present and it has the correct format, proceed to extract its "root name" and prepare the folder structure.
	root_name="${xyz_files_list[0]%-pos-1.xyz}"
	#3.1) Cleaning further the file name.
	root_name="${root_name%-proj}"

	mkdir -p neutral cation anion
	cp ../job-test ../test.inp ./neutral/ && cp ../job-test ../test.inp ./cation/ && cp ../job-test ../test.inp ./anion/

	#3.2) Copying and renaming the *.wfn file (if it does exist). Also creating files for the neutral form.
	wfn_file=( *.wfn )
	if [ ${#wfn_file[@]} -eq 0 ]; then
		echo -e "\e[31mNo wavefuncion found. Moving on.\e[0m"; echo
	else
		wfn_file_name="${wfn_file[0]}"
		cp $wfn_file_name ./neutral/ && mv ./neutral/"${wfn_file_name}" ./neutral/"${root_name}.wfn"
		WFN_FOUND=1
	fi

	touch "${root_name}_neutral.xyz" && echo "${lines_to_copy}" > "${root_name}_neutral.xyz" && mv "${root_name}_neutral.xyz" ./neutral/
	mv neutral/job-test neutral/"job-${root_name}_neutral" && mv neutral/test.inp neutral/"${root_name}_neutral.inp"

	#4) Checking if "rad" is a valid substring in the root name, remove "rad" from the names of the charged forms.
	if [[ "${root_name}" == *rad* ]]; then
		new_file_name="${root_name/rad/}"
		#4.1) Block of settings for the neutral form (radical).
		sed -i "s|${UKS_PLACEHOLDER}|UKS T|g" neutral/"${root_name}_neutral.inp"
		#4.2) Block of settings for the cationic form.
		touch "${new_file_name}_cation.xyz" && echo "${lines_to_copy}" > "${new_file_name}_cation.xyz" && mv "${new_file_name}_cation.xyz" ./cation/
		mv cation/job-test cation/"job-${new_file_name}_cation" && mv cation/test.inp cation/"${new_file_name}_cation.inp"
		sed -i "s|${UKS_PLACEHOLDER}|!UKS|g" cation/"${new_file_name}_cation.inp"
		#4.3) Block of settings for the anionic form.
		touch "${new_file_name}_anion.xyz" && echo "${lines_to_copy}" > "${new_file_name}_anion.xyz" && mv "${new_file_name}_anion.xyz" ./anion/ 
		mv anion/job-test anion/"job-${new_file_name}_anion" && mv anion/test.inp anion/"${new_file_name}_anion.inp"
		sed -i "s|${UKS_PLACEHOLDER}|!UKS|g" anion/"${new_file_name}_anion.inp"		
	else
		#5) If "rad" is NOT a valid substring in the root name, add "rad" in the names of the charged forms.
		new_file_name="${root_name}_rad"
		#5.1) Block of settings for the neutral form (non radical).
		sed -i "s|${UKS_PLACEHOLDER}|!UKS|g" neutral/"${root_name}_neutral.inp"
		#5.2) Block of settings for the cationic form.
		touch "${new_file_name}_cation.xyz" && echo "${lines_to_copy}" > "${new_file_name}_cation.xyz" && mv "${new_file_name}_cation.xyz" ./cation/
		mv cation/job-test cation/"job-${new_file_name}_cation" && mv cation/test.inp cation/"${new_file_name}_cation.inp"
		sed -i "s|${UKS_PLACEHOLDER}|UKS T|g" cation/"${new_file_name}_cation.inp"
		#5.3) Block of settings for the anionic form.
		touch "${new_file_name}_anion.xyz" && echo "${lines_to_copy}" > "${new_file_name}_anion.xyz" && mv "${new_file_name}_anion.xyz" ./anion/ 
		mv anion/job-test anion/"job-${new_file_name}_anion" && mv anion/test.inp anion/"${new_file_name}_anion.inp"
		sed -i "s|${UKS_PLACEHOLDER}|UKS T|g" anion/"${new_file_name}_anion.inp"		
	fi
	
	#6) Formatting job files and input files accordingly.
	#6.1) For the neutral form.
	sed -i "s|${JOB_INP_PLACEHOLDER}|${root_name}_neutral.inp|g" neutral/"job-${root_name}_neutral"
	sed -i "s|${JOB_OUT_PLACEHOLDER}|${root_name}_neutral.out|g" neutral/"job-${root_name}_neutral"
	sed -i "s|${CHARGE_PLACEHOLDER}|!CHARGE|g" neutral/"${root_name}_neutral.inp"
	sed -i "s|${XYZ_PLACEHOLDER}|${root_name}_neutral.xyz|g" neutral/"${root_name}_neutral.inp"
	sed -i "s|${PROJECT_PLACEHOLDER}|${root_name}_neutral|g" neutral/"${root_name}_neutral.inp"
	#6.2) Setting the .wfn file path and enabling print of MO cubefiles.
	if [[ $WFN_FOUND -eq 1 ]]; then	
		sed -i "s|${RESTART_PLACEHOLDER}|${RESTART_PLACEHOLDER} ./${root_name}.wfn|g" neutral/"${root_name}_neutral.inp"
	else	
		sed -i "s|${RESTART_PLACEHOLDER}||g" neutral/"${root_name}_neutral.inp"
	fi
	sed -i -E "s/^[[:space:]]*(RUN_TYPE)[[:space:]]+GEO_OPT/\\1 WFN_OPT/" neutral/"${root_name}_neutral.inp"
	touch temp && echo -e "\t&PRINT\n\t\t&MO_CUBES\n\t\tNHOMO 1\n\t\tNLUMO 1\n\t\tWRITE_CUBE\n\t\t&END MO_CUBES\n\t&END PRINT" > temp
	sed -i "/${MO_CUBES_PLACEHOLDER}/ {
		r temp
		d
	}" neutral/"${root_name}_neutral.inp"
	rm temp
	#6.3) For the charged forms.
	sed -i "s|${JOB_INP_PLACEHOLDER}|${new_file_name}_cation.inp|g" cation/"job-${new_file_name}_cation"
	sed -i "s|${JOB_OUT_PLACEHOLDER}|${new_file_name}_cation.out|g" cation/"job-${new_file_name}_cation"
	sed -i "s|${CHARGE_PLACEHOLDER}|CHARGE +1|g" cation/"${new_file_name}_cation.inp"
	sed -i "s|${XYZ_PLACEHOLDER}|${new_file_name}_cation.xyz|g" cation/"${new_file_name}_cation.inp"
	sed -i "s|${PROJECT_PLACEHOLDER}|${new_file_name}_cation|g" cation/"${new_file_name}_cation.inp"
	sed -i "s|${RESTART_PLACEHOLDER}||g" cation/"${new_file_name}_cation.inp"
	sed -i "s|${JOB_INP_PLACEHOLDER}|${new_file_name}_anion.inp|g" anion/"job-${new_file_name}_anion"
	sed -i "s|${JOB_OUT_PLACEHOLDER}|${new_file_name}_anion.out|g" anion/"job-${new_file_name}_anion"
	sed -i "s|${CHARGE_PLACEHOLDER}|CHARGE -1|g" anion/"${new_file_name}_anion.inp"
	sed -i "s|${XYZ_PLACEHOLDER}|${new_file_name}_anion.xyz|g" anion/"${new_file_name}_anion.inp"
	sed -i "s|${PROJECT_PLACEHOLDER}|${new_file_name}_anion|g" anion/"${new_file_name}_anion.inp"
	sed -i "s|${RESTART_PLACEHOLDER}||g" anion/"${new_file_name}_anion.inp"
	# sbatch neutral/"job-${root_name}_neutral" && sbatch cation/"job-${new_file_name}_cation" && sbatch anion/"job-${new_file_name}_anion"

	echo -e "\e[32mOperation completed in ${dir}.\e[0m"; echo
	cd .. || exit 1
done




#echo -e \e[31m  32 e 33 sono rosso verde e giallo   \e[0m