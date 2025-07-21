#include <stdio.h>
#include <unistd.h>

#define _NVIDIA_

#include "energy_pmt.h"
#include <mpi.h>
#include <omp.h>



int main()
{
  MPI_Init(NULL,NULL);

  int rank,size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int devID, numGPUs;
  numGPUs = omp_get_num_devices();
  devID = rank % numGPUs;

  omp_set_default_device(devID);
  
  PMT_CREATE(&devID,1);

  PMT_CPU_START("Kernel0");
  PMT_GPU_START("Kernel0", devID);

  sleep(2);
  
  PMT_CPU_START("Kernel");
  PMT_GPU_START("Kernel", devID);
  
  printf("Ciao mamma\n");
  sleep(2);
  
  PMT_CPU_STOP("Kernel");
  PMT_GPU_STOP("Kernel", devID);

  PMT_CPU_STOP("Kernel0");
  PMT_GPU_STOP("Kernel0", devID);

  PMT_CPU_SHOW("Kernel");
  PMT_GPU_SHOW("Kernel", devID);

  PMT_CPU_SHOW("Kernel0");
  PMT_GPU_SHOW("Kernel0", devID);

  MPI_Finalize();
  return 0;
}
