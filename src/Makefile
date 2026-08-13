# *****************************************************************
# *                        PINOCCHIO  V5.1                        *
# *  (PINpointing Orbit-Crossing Collapsed HIerarchical Objects)  *
# *****************************************************************
# 
# This code was written by
# Pierluigi Monaco, Tom Theuns, Giuliano Taffoni, Marius Lepinzan, 
# Chiara Moretti, Luca Tornatore, David Goz, Tiago Castro
# Copyright (C) 2025
# 
# github: https://github.com/pigimonaco/Pinocchio
# web page: http://adlibitum.oats.inaf.it/monaco/pinocchio.html
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Directory settings #

RUNDIR = ./

########## System-specific Configuration ############################

SYSTYPE ?= hpc-docker-nvidia
# SYSTYPE ?= hpc-docker-gnu

#####################################################################
#####################################################################
# The following variables should be passed from command line to make
# Executable name
EXEC         ?= pinocchio.x
# Compilation options

# C compiler
COMPILER     = mpicc
DEBUG        ?= NO
OMP          ?= YES
GPU          ?= NO
FULL_GPU     ?= YES
PPMT         ?= YES
SCOREP       ?= NO
NSIGHT       ?= NO
####################################################################

########## Preprocessor Definitions ################################

# Displacement LPT order # 

OPTIONS += -DTWO_LPT
OPTIONS += -DTHREE_LPT

# PLC reconstruction

# OPTIONS += -DPLC

# Dynamics of triaxial collapse #

OPTIONS += -DELL_CLASSIC
# OPTIONS += -DELL_SNG
# OPTIONS += -DTABULATED_CT

# Building groups and fragmentation #

# OPTIONS += -DCLASSIC_FRAGMENTATION

# Output #

# OPTIONS += -DSNAPSHOT
# OPTIONS += -DLIGHT_OUTPUT
# OPTIONS += -DLONGIDS
# OPTIONS += -DDOUBLE_PRECISION_PRODUCTS

# Beyond LambdaCDM models

# these are for neutrino cosmology
# OPTIONS += -DSCALE_DEPENDENT
# OPTIONS += -DREAD_PK_TABLE
# OPTIONS += -DONLY_MATTER_POWER
# OPTIONS += -DRECOMPUTE_DISPLACEMENTS

# add also these for f(R) gravity
# OPTIONS += -DMOD_GRAV_FR
# OPTIONS += -DFR0=1.e-8

# Other options # 

# OPTIONS += -DWHITENOISE
OPTIONS += -DNORADIATION


# -----------------------------------------------
# - This option impacts CPU code only
# - It is used by default using the GPU with OMP
# OPTIONS += -DCUSTOM_INTERPOLATION

#########################################################################################
#########################################################################################

ifeq ($(SCOREP)$(ENERGY_CPU),YESYES)
$(error "Score-P and PMT are mutually exclusive")
endif

ifeq ($(SCOREP)$(ENERGY_GPU),YESYES)
$(error "Score-P and PMT are mutually exclusive")
endif

################### SCOREP configuration ############################
ifeq ($(SCOREP), YES)
SCOREP_FLAG = scorep --user
OPTIONS += -D_SCOREP
else
SCOREP_FLAG = 
endif
#####################################################################

########## PPMT OPTION ###################################

ifeq ($(PPMT), YES)

# Acivate PPMT APIs in Pinocchio code
OPTIONS += -DPPMT

# MPI in Pinocchio is always ON
OPTIONS += -DPPMT_WITH_MPI

# NVIDIA if GPU is ON
ifeq ($(FULL_GPU), YES)
OPTIONS += -DPPMT_WITH_NVIDIA
endif

endif
############# PPMT ##########################################

######################################################
####################### GPU flag ####################
GPU_FLAG = 

ifeq ($(GPU), YES)
OPTIONS += -DGPU_OMP
GPU_FLAG = -gpu=ccnative -target=gpu
endif

ifeq ($(FULL_GPU), YES)
OPTIONS += -DGPU_OMP_FULL
GPU_FLAG = -mp=gpu -target=gpu -gpu=ccnative
endif

ifeq ($(NSIGHT), YES)
GPU_FLAG = -gpu=ccnative,lineinfo -target=gpu -gpu=nomanaged
endif

ifeq ($(DEBUG), YES)
# -----------------------------------------------
# - Debug option for multi task MPI run
OPTIONS += -DMPI_ATTACH_DEBUGGER
GPU_FLAG = -gpu=ccnative,debug,lineinfo -target=gpu -gpu=nomanaged 
endif

#######################################################

########## Preprocessor Definitions end ########## 

# OpenMP Configuration #

ifeq ($(OMP), YES)
OPTIONS += -DUSE_FFT_THREADS
# OMP_FLAG = -mp=multicore
OMP_FLAG = -fopenmp
OMP_FFTW = -lfftw3_omp -lfftw3_threads

ifeq ($(GPU), YES)
# OMP_FLAG = -mp=multicore,gpu
endif

ifeq ($(FULL_GPU), YES)
# OMP_FLAG = -mp=multicore,gpu
endif

else
ifeq ($(GPU), YES)
# OMP_FLAG = -mp=gpu
endif

ifeq ($(FULL_GPU), YES)
# OMP_FLAG = -mp=gpu
endif

OMP_FLAG =
OMP_FFTW =
endif # OMP, YES

########################### SYSTYPE CONFIGURATION ###################################

###################### LeonardoBoost ######################

ifeq ($(SYSTYPE), LeonardoBoost)

CDEBUG      = -g -O0 -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)
COPTIMIZED  = -O3 -fast -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)

LIBDIR      = /leonardo_scratch/fast/CNHPC_1498509/lib/nvhpc-23.11
FFTW        = $(LIBDIR)/fftw/fftw-3.3.10
FFTW_LIBR   = -L$(FFTW)/lib -lfftw3_mpi -lfftw3 $(OMP_FFTW)
FFTW_INCL   = -I$(FFTW)/include


GSL         = $(LIBDIR)/gsl/gsl-2.7.1
GSL_LIBR    = -L$(GSL)/lib -lgsl -lgslcblas -lm
GSL_INCL    = -I$(GSL)/include

PFFT        = $(LIBDIR)/pfft/pfft
PFFT_LIBR   = -L$(PFFT)/lib -lpfft
PFFT_INCL   = -I$(PFFT)/include


endif

###################### LeonardoBoost ######################

ifeq ($(SYSTYPE),hpc-docker-nvidia)

$(info Compiling hpc-docker-nvidia)

EXEC = pinocchio_$(SYSTYPE)

CDEBUG      = -g -O0 -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)
COPTIMIZED  = -O3 -fast -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)

LIBDIR      = /usr/local

FFTW        = $(LIBDIR)/fftw/fftw-3.3.10
FFTW_LIBR   = -L$(FFTW)/lib -lfftw3_mpi -lfftw3 $(OMP_FFTW)
FFTW_INCL   = -I$(FFTW)/include

GSL         = $(LIBDIR)/gsl/gsl-2.8
GSL_LIBR    = -L$(GSL)/lib -lgsl -lgslcblas -lm
GSL_INCL    = -I$(GSL)/include

PFFT        = $(LIBDIR)/pfft/1.0.8-alpha
PFFT_LIBR   = -L$(PFFT)/lib -lpfft
PFFT_INCL   = -I$(PFFT)/include

PPMT_PATH   = /workspace/tmp/ppmt
ifeq ($(PPMT),YES)
PPMT_INCL   = -I$(PPMT_PATH)/include
PPMT_LIBR   = -L$(PPMT_PATH)/lib/nvc++ -lpmt
ifeq ($(FULL_GPU),YES)
PPMT_LIBR += -lppmt_mpi_nvidia
else
PPMT_LIBR += -lppmt_mpi
endif # FULL_GPU

endif # PPMT

endif # SYSTYPE

ifeq ($(SYSTYPE),hpc-docker-gnu)

$(info Compiling hpc-docker-gnu)

EXEC = pinocchio_$(SYSTYPE)

CDEBUG      = -g -O0 -march=native -mtune=native -fno-omit-frame-pointer $(OMP_FLAG)
COPTIMIZED  = -O3 -march=native -mtune=native $(OMP_FLAG)

LIBDIR      = /usr/local

FFTW        = $(LIBDIR)/fftw/fftw-3.3.10
FFTW_LIBR   = -L$(FFTW)/lib -lfftw3_mpi -lfftw3 $(OMP_FFTW)
FFTW_INCL   = -I$(FFTW)/include

GSL         = $(LIBDIR)/gsl/gsl-2.8
GSL_LIBR    = -L$(GSL)/lib -lgsl -lgslcblas -lm
GSL_INCL    = -I$(GSL)/include

PFFT        = $(LIBDIR)/pfft/1.0.8-alpha
PFFT_LIBR   = -L$(PFFT)/lib -lpfft
PFFT_INCL   = -I$(PFFT)/include

PPMT_PATH   = /workspace/tmp/ppmt
ifeq ($(PPMT),YES)
PPMT_INCL   = -I$(PPMT_PATH)/include
PPMT_LIBR   = -L$(PPMT_PATH)/lib/mpic++ -lpmt -lppmt_mpi
endif # PPMT

endif # SYSTYPE


ifeq ($(SYSTYPE), Magellanus)

CDEBUG      = -g -O0 -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)
COPTIMIZED  = -O3 -fast -Minfo=all -v -Mneginfo -march=native -mtune=native -fomit-frame-pointer $(GPU_FLAG) $(OMP_FLAG)
# COPTIMIZED  = -O3 -march=native -mtune=native -fomit-frame-pointer -ftree-vectorize $(GPU_FLAG) $(OMP_FLAG)
#COPTIMIZED  = -g -O3 -march=native -mtune=native $(GPU_FLAG) $(OMP_FLAG)
#COPTIMIZED      = -g -O0 -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)

##################### DA CAMBIARE ###############################
# GPU_FLAG   = -gpu=ccnative,debug,lineinfo -target=gpu -gpu=nomanaged
# OMP_FLAG   = -mp=multicore,gpu
# COPTIMIZED = -g -O0 -Minfo=all -v -Mneginfo $(GPU_FLAG) $(OMP_FLAG)
##############################################################

LIBDIR      = /data/NVC_LIB
FFTW        = $(LIBDIR)/FFT_lib/fftw-3.3.10/local
FFTW_LIBR   = -L$(FFTW)/lib -lfftw3_mpi -lfftw3 $(OMP_FFTW)
FFTW_INCL   = -I$(FFTW)/include

GSL         = $(LIBDIR)/gsl-2.8/local
GSL_LIBR    = -L$(GSL)/lib -lgsl -lgslcblas -lm
GSL_INCL    = -I$(GSL)/include

PFFT        = $(LIBDIR)/FFT_lib/pfft/pfft-1.0.8-alpha/local
PFFT_LIBR   = -L$(PFFT)/lib -lpfft
PFFT_INCL   = -I$(PFFT)/include


PMT         = /space/Giovanni/Pinocchio_dev/Pinocchio_parallel_pmt/src/energy_parallel
PMT_LIBR    = -L$(PMT) -lpmt_parallel
PMT_INCL    = -I$(PMT)

endif

##########################################################################


# ###################### PLEIADI ######################

ifeq ($(SYSTYPE), pleiadi)

COPTIMIZED  = -O3 -g -fopenmp -march=native -mtune=native -ftree-vectorize
FFTW        = /u/dgoz/lib/fftw-3.3.10_pleiadi
FFTW_LIBR   = -L$(FFTW)/lib -lfftw3_mpi -lfftw3 $(OMP_FFTW)
FFTW_INCL   = -I$(FFTW)/include
PFFT        = /u/dgoz/lib/pfft-1.0.8-alpha_pleiadi
PFFT_LIBR   = -L$(PFFT)/lib -lpfft
PFFT_INCL   = -I$(PFFT)/include
MPI_LIBR    =
MPI_INCL    =
GSL         = /u/dgoz/lib/gsl-2.7.1_pleiadi
GSL_LIBR    = -L$(GSL)/lib -lgsl -lgslcblas -lm
GSL_INCL    = -I$(GSL)/include

endif
######################################################

########## System-specific Configuration end ########## 

# Include paths for libraries #

INC =  $(PFFT_INCL) $(FFTW_INCL) $(MPI_INCL) $(GSL_INCL) $(PPMT_INCL)

# Library flags #

LIB = -lm -lstdc++ $(PFFT_LIBR) $(FFTW_LIBR) $(MPI_LIBR) $(GSL_LIBR) $(PPMT_LIBR)

# Compiler options : choose from CDEBUG or COPTIMIZED #

ifeq ($(DEBUG), YES)
COPTS = $(CDEBUG)
else
COPTS = $(COPTIMIZED)
endif

# Print GPU_FLAG and COPTS for debugging
$(info GPU_FLAG = $(GPU_FLAG))
$(info COPTS    = $(COPTS))


# Source files #

OBJECTS = fmax.o  variables.o  cubic_spline_interpolation.o cubic_spline_interpolation_full_GPU.o cosmo.o initialization.o fmax-pfft.o GenIC.o \
	ReadParamfile.o allocations.o LPT.o distribute.o collapse_times.o collapse_times_GPU.o \
	fragment.o build_groups.o write_halos.o write_snapshot.o pinocchio.o mpi_debugger.o

# Main targets and rules

$(EXEC): $(OBJECTS) Makefile
	$(SCOREP_FLAG) $(COMPILER) $(COPTS) $(OPTIONS) -o $(RUNDIR)$(EXEC) $(OBJECTS) $(LIB)
	ldd $(RUNDIR)$(EXEC)

run_planner: $(OBJECTS) run_planner.o Makefile
	$(CC) $(INC) $(COPTS) -o run_planner run_planner.o $(OBJECTS) $(LIB)	

# Generic rule for compiling source files #

%.o: %.c Makefile pinocchio.h def_splines.h 
	$(SCOREP_FLAG) $(COMPILER) $(INC) $(COPTS) $(OPTIONS) -c $<


# Clean target #

clean:
	rm -f *.o *~ $(EXEC) run_planner
