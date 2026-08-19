#!/bin/bash

#SBATCH --job-name=PPMT_Booster
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --gres=gpu:4
#SBATCH --time=03:00:00
#SBATCH --partition=boost_usr_prod
##SBATCH --qos=boost_qos_dbg
#SBATCH --account=INA24_C6B02
#SBATCH --output=PPMT_Booster.out
#SBATCH --error=PPMT_Booster.err

module purge

# BOOSTER load modules
ml nvhpc/25.11 hpcx-mpi/2.25.1 gcc/12.2.0 fftw/3.3.10--hpcx-mpi--2.25.1--nvhpc--25.11

SYSTEM=Booster
############################################## TO EDIT ###########################################################
##################################################################################################################
WHERE_I_AM=${PWD}

# Expand Slurm's allocation into an array of individual hostnames
mapfile -t ALL_NODES < <(scontrol show hostnames "${SLURM_JOB_NODELIST}")

HPCTOOLKIT=0
TASKS_PER_NODE=( 4 )
MAP="numa" # 2 numa in Booster
NUMA_PER_NODE=2

# export OMP_TARGET_OFFLOAD=mandatory
export OMP_PROC_BIND=true
export OMP_WAIT_POLICY=ACTIVE

PFFT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/nvhpc-25.11/pfft/pfft
GSL_ROOT=/leonardo/home/userexternal/dgoz0000/lib/nvhpc-25.11/gsl/gsl-2.8
PPMT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/ppmt/booster

# CUDA is already inside NVHPC-25
export CUDA_HOME=/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-25.11-ayzlbce6ohpmv72ncfv4ogitmppp2usq/Linux_x86_64/25.11
export CUPTI=${CUDA_HOME}/cuda/12.9/extras/CUPTI/lib64
export CUDA_MATH_LIB=${CUDA_HOME}/math_libs/12.9/lib64:${CUDA_HOME}/cuda/12.9/targets/x86_64-linux/lib:${CUPTI}
export PATH=${CUDA_HOME}/cuda/bin:${PATH}
GCC_LIB_DIR=$(dirname $(gcc -print-file-name=libstdc++.so.6))
export LD_LIBRARY_PATH=${GCC_LIB_DIR}:${CUDA_MATH_LIB}:${PFFT_ROOT}/lib:${GSL_ROOT}/lib:${PPMT_ROOT}/lib64/mpic++:${NVHPC_MATH}/lib64:${LD_LIBRARY_PATH}


if [[ ${HPCTOOLKIT} -eq 1 ]]
then
    SYSTEM="${SYSTEM}_HPCtoolkit"
    HPCTOOLKIT_ROOT=/leonardo/home/userexternal/dgoz0000/lib/HPCTOOLKIT/booster
    export LD_LIBRARY_PATH=${HPCTOOLKIT_ROOT}/lib64:${LD_LIBRARY_PATH}
    export PATH=${HPCTOOLKIT_ROOT}/bin:${PATH}
fi

# Compile the code
printf "\n\t Compiling the code...\n"
cd ../src
make clean && make |& tee compile.txt

EXEC=$(realpath pinocchio_LeonardoBoost)

cd ${WHERE_I_AM}
PARAMFILE=$(realpath parameter_file)

OUT_DIR=${PWD}/PPMT_report_${SYSTEM}

# loop over MPI tasks per node
for MPI_PER_NODE in ${TASKS_PER_NODE[@]} ; do
    # loop over nodes
    for ((NODES=${SLURM_NNODES} ; NODES<=${SLURM_NNODES} ; NODES++)) ; do
	# Calculate total MPI ranks for this run
	NT=$(( NODES * MPI_PER_NODE ))

	# Calculate the PPR [2 numa in Booster]
	PPR=$(( MPI_PER_NODE / NUMA_PER_NODE ))

	# Calculate OMP threads per MPI rank
	export OMP_NUM_THREADS=$((32 / MPI_PER_NODE))
	
	# Slice the host array to get only the number of nodes needed for this iteration
	NODE_SUBSET=("${ALL_NODES[@]:0:NODES}")

	# Append ':32' to every node in the subset so MPI knows it has 32 slots per node
	HOST_LIST=$(IFS=,; echo "${NODE_SUBSET[*]/%/:32}")

	OUT_FILE=output_${NODES}_nodes_${NT}_MPI_${MPI_PER_NODE}_MPI_per_node_${OMP_NUM_THREADS}_OMP_${SYSTEM}.txt
	
	printf "\n\t --> Running on ${nodes} Node(s) (${HOST_LIST})"
	printf "\n\t Total Ranks (-n): ${NT} | Layout: ${PPR} ranks per ${MAP}"

	if [[ ${HPCTOOLKIT} -eq 1 ]]
	then
	    OUT_HPCRUN="hpctoolkit-measurements-${NODES}_nodes-${NT}_MPI"
	    OUT_HPCPROF="hpctoolkit-database-${NODES}_nodes-${NT}_MPI"

	    rm -rf "${OUT_HPCRUN}" "${OUT_HPCPROF}"
	    
	    printf "\n\t HPCTOOLKIT \n"
	    printf "\n\t mpirun -n ${NT} --host ${HOST_LIST} --map-by ppr:${PPR}:${MAP}:PE=${OMP_NUM_THREADS} --bind-to core --report-bindings hpcrun --output ${OUT_HPCRUN} -e gpu=cuda -tt -e REALTIME ${EXEC} 1000 \n"
	    mpirun -n ${NT} \
	    	   --host "${HOST_LIST}" \
	    	   --map-by ppr:${PPR}:${MAP}:PE=${OMP_NUM_THREADS} \
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
	    printf "\n\t mpirun -n ${NT} --host ${HOST_LIST} --map-by ppr:${PPR}:${MAP}:PE=${OMP_NUM_THREADS} --bind-to core --report-bindings ${EXEC} parameter_file |& tee ${OUT_FILE} \n"
	    mpirun -n ${NT} \
		   --host "${HOST_LIST}" \
		   --map-by ppr:${PPR}:${MAP}:PE=${OMP_NUM_THREADS} \
		   --bind-to core \
		   --report-bindings \
		   -x LD_LIBRARY_PATH \
		   ${EXEC} ${PARAMFILE} |& tee ${OUT_FILE}
	fi
	
	OUT_SUBDIR=${OUT_DIR}/PPMT_${NODES}_nodes/MPI_${MPI_PER_NODE}_OMP_${OMP_NUM_THREADS}
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
