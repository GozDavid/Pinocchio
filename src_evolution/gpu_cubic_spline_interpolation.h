#ifndef GPU_CUBIC_SPLINE_H
#define GPU_CUBIC_SPLINE_H

typedef struct
{
  int size;
  double *x;
  double *y;
  double *d2y_data;
  double *coeff_a; 
  double *coeff_b;  
  double *coeff_c; 
  double *coeff_d;  
} CubicSpline;

extern CubicSpline *gpu_spline, *h_gpu_spline;
#pragma omp declare target(gpu_spline)

double custom_cubic_spline_eval(CubicSpline *const spline, const double x);
#ifdef GPU_OMP
#pragma omp declare target(custom_cubic_spline_eval)
#endif // GPU_OMP

void custom_cubic_spline_init(      CubicSpline *const restrict spline,
			      const double      *const restrict x_data,
			      const double      *const restrict y_data,
			      const int                         size);

CubicSpline* custom_cubic_spline_alloc(const int size);
void calculate_second_derivatives(CubicSpline *const spline);
void cubic_spline_coefficients(CubicSpline *const spline);
void custom_cubic_spline_free(CubicSpline *spline);

#endif // GPU_CUBIC_SPLINE_H
