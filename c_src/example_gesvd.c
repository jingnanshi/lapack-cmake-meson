/*
from http://www.netlib.org/lapack/explore-html/d5/df8/example___d_g_e_s_v__colmajor_8c_source.html

    LAPACKE_dgesv Example
    =====================

    The program computes the solution to the system of linear
    equations with a square matrix A and multiple
    right-hand sides B, where A is the coefficient matrix
    and b is the right-hand side matrix:

    Description
    ===========

    The routine solves for X the system of linear equations A*X = B,
    where A is an n-by-n matrix, the columns of matrix B are individual
    right-hand sides, and the columns of X are the corresponding
    solutions.

    The LU decomposition with partial pivoting and row interchanges is
    used to factor A as A = P*L*U, where P is a permutation matrix, L
    is unit lower triangular, and U is upper triangular. The factored
    form of A is then used to solve the system of equations A*X = B.

    LAPACKE Interface
    =================

    LAPACKE_dgesv (col-major, high-level) Example Program Results

   -- LAPACKE Example routine (version 3.7.0) --
   -- LAPACK is a software package provided by Univ. of Tennessee,    --
   -- Univ. of California Berkeley, Univ. of Colorado Denver and NAG Ltd..--
      December 2016

 */
 /* Includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#if USEMKL == 1
#include "mkl_lapacke.h"
#elif USEATLAS == 1
#include "cblas.h"
#include "clapack.h"
#elif USEOpenBLAS == 1
#include "cblas.h"
#else
#include "lapacke.h"
#endif

/* Main program */
int main(int argc, char **argv) {

     /* Locals */
      int n, nrhs, lda, ldb, info;
      int i, j;
     /* Local arrays */
             double *A, *b;
             int *ipiv;

     /* Default Value */
         n = 5; nrhs = 1;

     /* Arguments */
         for( i = 1; i < argc; i++ ) {
             if( strcmp( argv[i], "-n" ) == 0 ) {
                   n  = atoi(argv[i+1]);
                   i++;
                 }
                     if( strcmp( argv[i], "-nrhs" ) == 0 ) {
                         nrhs  = atoi(argv[i+1]);
                         i++;
                     }
             }

     /* Initialization */
     lda=n, ldb=n;
             A = (double *)malloc(n*n*sizeof(double)) ;
             if (A==NULL){ printf("error of memory allocation\n"); return 1; }
             b = (double *)malloc(n*nrhs*sizeof(double)) ;
             if (b==NULL){ printf("error of memory allocation\n"); return 1; }
             ipiv = (int *)malloc(n*sizeof(int)) ;
             if (ipiv==NULL){ printf("error of memory allocation\n"); return 1; }

     for( i = 0; i < n; i++ ) {
             for( j = 0; j < n; j++ ) A[i+j*lda] = ((double) rand()) / ((double) RAND_MAX) - 0.5;
             }

             for(i=0;i<n*nrhs;i++)
                     b[i] = ((double) rand()) / ((double) RAND_MAX) - 0.5;

     /* Print Entry Matrix */
     //print_matrix_colmajor( "Entry Matrix A", n, n, A, lda );
     /* Print Right Rand Side */
     //print_matrix_colmajor( "Right Rand Side b", n, nrhs, b, ldb );
     //printf( "\n" );

     /* Executable statements */
     /* printf( "dgesv (row-major, high-level) Example Program Results\n" ); */
     /* Solve the equations A*X = B */
#if USEATLAS==1
     info = clapack_dgesv( 102, n, nrhs, A, lda, ipiv, b, ldb );
#elif USEOpenBLAS == 1
     cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,n,n,n,1, A, lda, b, ldb, 0, A, lda);
#else
     info = LAPACKE_dgesv( LAPACK_COL_MAJOR, n, nrhs, A, lda, ipiv, b, ldb );
#endif
     /* Check for the exact singularity */
     if( info > 0 ) {
             printf( "The diagonal element of the triangular factor of A,\n" );
             printf( "U(%i,%i) is zero, so that A is singular;\n", info, info );
             printf( "the solution could not be computed.\n" );
             return 1;
     }
     if (info < 0) return 1;
     /* Print solution */
     // print_matrix_colmajor( "Solution", n, nrhs, b, ldb );
     /* Print details of LU factorization */
    // print_matrix_colmajor( "Details of LU factorization", n, n, A, lda );
     /* Print pivot indices */
     // print_vector( "Pivot indices", n, ipiv );
     return 0;
} /* End of LAPACKE_dgesv Example */
