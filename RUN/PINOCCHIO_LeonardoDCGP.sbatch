#!/bin/bash

#SBATCH --job-name=PPMT_DCGP
#SBATCH --nodes=8
#SBATCH --exclusive
#SBATCH --time=03:00:00
#SBATCH --partition=dcgp_usr_prod
#SBATCH --account=INA24_C6B02_0
#SBATCH --output=PPMT_DCGP_%j.out
#SBATCH --error=PPMT_DCGP_%j.err

module purge

# DCGP load modules
ml cmake gcc/12.2.0 fftw/3.3.10--openmpi--4.1.6--gcc--12.2.0-spack0.22 gsl/2.7.1--gcc--12.2.0-spack0.22

SYSTEM=DCGP
############################################## TO EDIT ###########################################################
##################################################################################################################
WHERE_I_AM=${PWD}

# Expand Slurm's allocation into an array of individual hostnames
mapfile -t ALL_NODES < <(scontrol show hostnames "${SLURM_JOB_NODELIST}")

HPCTOOLKIT=0
TASKS_PER_NODE=( 56 )
MAP="socket" # 2 sockets in DCGP
SOCKET_PER_NODE=2

unset OMP_PROC_BIND
unset OMP_PLACES
export OMP_DISPLAY_AFFINITY=true

PFFT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/DCGP/pfft
PPMT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/ppmt/dcgp

export LD_LIBRARY_PATH=${PFFT_ROOT}/lib:${PPMT_ROOT}/lib64/mpic++:${LD_LIBRARY_PATH}

if [[ ${HPCTOOLKIT} -eq 1 ]]
then
    SYSTEM="${SYSTEM}_HPCtoolkit"
    HPCTOOLKIT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/HPCTOOLKIT/dcgp
    export LD_LIBRARY_PATH=${HPCTOOLKIT_ROOT}/lib64:${LD_LIBRARY_PATH}
    export PATH=${HPCTOOLKIT_ROOT}/bin:${PATH}
fi

# Compile the code
printf "\n\t Compiling the code...\n"
cd ../src
make clean && make |& tee compile.txt

EXEC=$(realpath pinocchio_LeonardoDCGP)

cd ${WHERE_I_AM}
PARAMFILE=$(realpath parameter_file)

OUT_DIR=${PWD}/PPMT_report_${SYSTEM}

# loop over MPI tasks per node
for MPI_PER_NODE in ${TASKS_PER_NODE[@]} ; do
    # loop over nodes
    for ((NODES=1 ; NODES<=${SLURM_NNODES} ; NODES++)) ; do
	# Calculate total MPI ranks for this run
	NT=$(( NODES * MPI_PER_NODE ))

	# Calculate the PPR [2 sockets in DCGP]
	PPR=$(( MPI_PER_NODE / SOCKET_PER_NODE ))

	# Calculate OMP threads per MPI rank
	PE=$((112 / MPI_PER_NODE))
	export OMP_NUM_THREADS=1
	
	# Slice the host array to get only the number of nodes needed for this iteration
	NODE_SUBSET=("${ALL_NODES[@]:0:NODES}")

	# Append ':32' to every node in the subset so MPI knows it has 112 slots per node
	HOST_LIST=$(IFS=,; echo "${NODE_SUBSET[*]/%/:112}")

	OUT_FILE=output_${NODES}_nodes_${NT}_MPI_${MPI_PER_NODE}_MPI_per_node_${OMP_NUM_THREADS}_OMP_${SYSTEM}.txt
	
	printf "\n\t --> Running on ${NODES} Node(s) (${HOST_LIST})"
	printf "\n\t Total Ranks (-n): ${NT} | Layout: ${PPR} ranks per ${MAP}"

	if [[ ${HPCTOOLKIT} -eq 1 ]]
	then
	    OUT_HPCRUN="hpctoolkit-measurements-${NODES}_nodes-${NT}_MPI"
	    OUT_HPCPROF="hpctoolkit-database-${NODES}_nodes-${NT}_MPI"

	    rm -rf "${OUT_HPCRUN}" "${OUT_HPCPROF}"
	    
	    printf "\n\t HPCTOOLKIT \n"
	    printf "\n\t mpirun -n ${NT} --host ${HOST_LIST} --map-by ppr:${PPR}:${MAP}:PE=${PE} --bind-to core --report-bindings hpcrun --output ${OUT_HPCRUN} -e gpu=cuda -tt -e REALTIME ${EXEC} 1000 \n"
	    mpirun -n ${NT} \
	    	   --host "${HOST_LIST}" \
	    	   --map-by ppr:${PPR}:${MAP}:PE=${PE} \
	    	   --bind-to core \
	    	   --report-bindings \
	    	   -x LD_LIBRARY_PATH \
	    	   hpcrun --output ${OUT_HPCRUN} -e gpu=cuda -tt -e REALTIME \
	    	   ${EXEC} ${PARAMFILE} |& tee ${OUT_FILE}

	    printf "\n\t Analyze the structure of that directory"
	    printf "\n\t hpcstruct ${OUT_HPCRUN}"
	    hpcstruct ${OUT_HPCRUN} |& tee -a ${OUT_FILE}

	    printf "\n\t Generate the final database using your custom folder"
	    printf "\n\t hpcprof -j ${NT} -o ${OUT_HPCPROF} ${OUT_HPCRUN}"
	    hpcprof -j ${NT} -o ${OUT_HPCPROF} ${OUT_HPCRUN} |& tee -a ${OUT_FILE}
	else
	    printf "\n\t mpirun -n ${NT} --host ${HOST_LIST} --map-by ppr:${PPR}:${MAP}:PE=${PE} --bind-to core --report-bindings ${EXEC} parameter_file |& tee ${OUT_FILE} \n"
	    mpirun -n ${NT} \
		   --host "${HOST_LIST}" \
		   --map-by ppr:${PPR}:${MAP}:PE=${PE} \
		   --bind-to core \
		   --report-bindings \
		   -x LD_LIBRARY_PATH \
		   ${EXEC} ${PARAMFILE} |& tee ${OUT_FILE}
	fi
	
	OUT_SUBDIR=${OUT_DIR}/PPMT_${NODES}_nodes/MPI_${MPI_PER_NODE}_OMP_${OMP_NUM_THREADS}_PPMT_NO_FFT
	mkdir -p ${OUT_SUBDIR}
	mv PPMT_report_*.txt ${OUT_FILE} ${OUT_SUBDIR}
	if [[ ${HPCTOOLKIT} -eq 1 ]]
	then
	    mv ${OUT_HPCRUN} ${OUT_HPCPROF} ${OUT_SUBDIR}
	fi

	echo "-----------------------------------------------------------------"
    done # loop over nodes
done # loop over MPI tasks per node

cd ${WHERE_I_AM}
rm -rf pinocchio.*

printf "\n\t END OF GAME!!! \n\n"

exit 0
