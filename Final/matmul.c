#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

// 動態配置矩陣記憶體
float *alloc_matrix(int rows, int cols)
{
    return (float *)malloc(sizeof(float) * rows * cols);
}

// 一般矩陣乘法：C = A × B
void matrix_multiply(float *A, float *B, float *C, int m, int n, int l)
{
    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < l; ++j)
        {
            C[i * l + j] = 0;
            for (int k = 0; k < n; ++k)
            {
                C[i * l + j] += A[i * n + k] * B[k * l + j];
            }
            // 四捨五入以減少精度誤差
            C[i * l + j] = (int)(C[i * l + j] + 0.5);
        }
    }
}

// 矩陣鏈相乘的動態規劃演算法
void matrix_chain_order(int *dims, int n, int **m, int **s)
{
    for (int i = 1; i <= n; ++i)
        m[i][i] = 0;

    for (int l = 2; l <= n; ++l)
    {
        for (int i = 1; i <= n - l + 1; ++i)
        {
            int j = i + l - 1;
            m[i][j] = INT_MAX;
            for (int k = i; k < j; ++k)
            {
                int cost = m[i][k] + m[k + 1][j] + dims[i - 1] * dims[k] * dims[j];
                if (cost < m[i][j])
                {
                    m[i][j] = cost;
                    s[i][j] = k;
                }
            }
        }
    }
}

// 透過最佳的分割順序遞迴進行矩陣相乘
float *matrix_chain_multiply(float **matrices, int *dims, int i, int j, int **s)
{
    if (i == j)
        return matrices[i];

    int k = s[i][j];
    float *A = matrix_chain_multiply(matrices, dims, i, k, s);
    float *B = matrix_chain_multiply(matrices, dims, k + 1, j, s);

    int m = dims[i - 1], n = dims[k], l = dims[j];
    float *C = alloc_matrix(m, l);
    matrix_multiply(A, B, C, m, n, l);

    // 如果 A 或 B 是中間結果（不是原始矩陣），則需要釋放記憶體
    if (i != k)
        free(A);
    if (k + 1 != j)
        free(B);

    return C;
}

// 從檔案讀取測試案例
void read_testcase(const char *filename, int *n_ptr, int **dims_ptr, float ***matrices_ptr)
{
    FILE *file = fopen(filename, "r");
    if (!file)
    {
        printf("無法開啟檔案: %s\n", filename);
        exit(1);
    }

    int n;
    fscanf(file, "%d", &n);
    *n_ptr = n;

    int *dims = (int *)malloc((n + 1) * sizeof(int));
    float **matrices = (float **)malloc((n + 1) * sizeof(float *));

    // 讀取每個矩陣
    for (int i = 1; i <= n; i++)
    {
        int rows, cols;
        fscanf(file, "%d %d", &rows, &cols);

        dims[i] = cols;
        if (i == 1)
            dims[0] = rows;

        matrices[i] = alloc_matrix(rows, cols);

        // 讀取矩陣元素
        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                float val;
                fscanf(file, "%f", &val);
                matrices[i][r * cols + c] = val;
            }
        }
    }

    fclose(file);
    *dims_ptr = dims;
    *matrices_ptr = matrices;
}

// 主程式
int main(int argc, char *argv[])
{
    int test_case = 0; // 預設使用測試案例 0

    // 如果有命令列參數，使用指定的測試案例
    if (argc > 1)
    {
        test_case = atoi(argv[1]);
    }

    printf("使用測試案例: %d\n", test_case);

    char filename[100];
    sprintf(filename, "testcase/public/testcase_%02d.txt", test_case);

    int n;
    int *dims;
    float **matrices;

    // 讀取測試案例檔案
    read_testcase(filename, &n, &dims, &matrices);

    // 配置 DP 陣列
    int **m = malloc((n + 1) * sizeof(int *));
    int **s = malloc((n + 1) * sizeof(int *));
    for (int i = 0; i <= n; ++i)
    {
        m[i] = malloc((n + 1) * sizeof(int));
        s[i] = malloc((n + 1) * sizeof(int));
    }

    // 計算最小乘法次數
    matrix_chain_order(dims, n, m, s);
    printf("最小標量乘法次數: %d\n", m[1][n]);

    // 使用最佳順序計算矩陣乘積
    float *result = matrix_chain_multiply(matrices, dims, 1, n, s);

    // 輸出結果矩陣
    int final_rows = dims[0];
    int final_cols = dims[n];

    // 針對所有測試案例，使用矩陣格式輸出 (每行包含該行的所有元素，以空格分隔)
    for (int i = 0; i < final_rows; ++i)
    {
        for (int j = 0; j < final_cols; ++j)
        {
            printf("%.0f", result[i * final_cols + j]);
            if (j < final_cols - 1)
                printf(" ");
        }
        printf("\n");
    }

    // 釋放記憶體
    free(result);
    for (int i = 1; i <= n; ++i)
        free(matrices[i]);
    free(matrices);
    free(dims);

    // 釋放 DP 陣列的記憶體
    for (int i = 0; i <= n; ++i)
    {
        free(m[i]);
        free(s[i]);
    }
    free(m);
    free(s);

    return 0;
}

// #include <stdio.h>
// #include <stdlib.h>
// #include <limits.h>

// // 動態配置矩陣記憶體
// float *alloc_matrix(int rows, int cols)
// {
//     return (float *)malloc(sizeof(float) * rows * cols);
// }

// // 一般矩陣乘法：C = A × B
// void matrix_multiply(float *A, float *B, float *C, int m, int n, int l)
// {
//     for (int i = 0; i < m; ++i)
//         for (int j = 0; j < l; ++j)
//         {
//             C[i * l + j] = 0;
//             for (int k = 0; k < n; ++k)
//                 C[i * l + j] += A[i * n + k] * B[k * l + j];
//         }
// }

// // 矩陣鏈相乘的動態規劃演算法
// void matrix_chain_order(int *dims, int n, int **m, int **s)
// {
//     for (int i = 1; i <= n; ++i)
//         m[i][i] = 0;

//     for (int l = 2; l <= n; ++l)
//     {
//         for (int i = 1; i <= n - l + 1; ++i)
//         {
//             int j = i + l - 1;
//             m[i][j] = INT_MAX;
//             for (int k = i; k < j; ++k)
//             {
//                 int cost = m[i][k] + m[k + 1][j] + dims[i - 1] * dims[k] * dims[j];
//                 if (cost < m[i][j])
//                 {
//                     m[i][j] = cost;
//                     s[i][j] = k;
//                 }
//             }
//         }
//     }
// }

// // 透過最佳的分割順序遞迴進行矩陣相乘
// float *matrix_chain_multiply(float **matrices, int *dims, int i, int j, int **s)
// {
//     if (i == j)
//         return matrices[i];

//     int k = s[i][j];
//     float *A = matrix_chain_multiply(matrices, dims, i, k, s);
//     float *B = matrix_chain_multiply(matrices, dims, k + 1, j, s);

//     int m = dims[i - 1], n = dims[k], l = dims[j];
//     float *C = alloc_matrix(m, l);
//     matrix_multiply(A, B, C, m, n, l);

//     // 如果 A 或 B 是中間結果（不是原始矩陣），則需要釋放記憶體
//     if (i != k)
//         free(A);
//     if (k + 1 != j)
//         free(B);

//     return C;
// }

// // 從檔案讀取測試案例
// void read_testcase(const char *filename, int *n_ptr, int **dims_ptr, float ***matrices_ptr)
// {
//     FILE *file = fopen(filename, "r");
//     if (!file)
//     {
//         printf("無法開啟檔案: %s\n", filename);
//         exit(1);
//     }

//     int n;
//     fscanf(file, "%d", &n);
//     *n_ptr = n;

//     int *dims = (int *)malloc((n + 1) * sizeof(int));
//     float **matrices = (float **)malloc((n + 1) * sizeof(float *));

//     // 讀取每個矩陣
//     for (int i = 1; i <= n; i++)
//     {
//         int rows, cols;
//         fscanf(file, "%d %d", &rows, &cols);

//         dims[i] = cols;
//         if (i == 1)
//             dims[0] = rows;

//         matrices[i] = alloc_matrix(rows, cols);

//         // 讀取矩陣元素
//         for (int r = 0; r < rows; r++)
//         {
//             for (int c = 0; c < cols; c++)
//             {
//                 float val;
//                 fscanf(file, "%f", &val);
//                 matrices[i][r * cols + c] = val;
//             }
//         }
//     }

//     fclose(file);
//     *dims_ptr = dims;
//     *matrices_ptr = matrices;
// }

// // 主程式
// int main(int argc, char *argv[])
// {
//     int test_case = 3; // 預設使用測試案例 3

//     // 如果有命令列參數，使用指定的測試案例
//     if (argc > 1)
//     {
//         test_case = atoi(argv[1]);
//     }

//     printf("使用測試案例: %d\n", test_case);

//     char filename[100];
//     sprintf(filename, "testcase/public/testcase_%02d.txt", test_case);

//     int n;
//     int *dims;
//     float **matrices;

//     // 讀取測試案例檔案
//     read_testcase(filename, &n, &dims, &matrices);

//     // 配置 DP 陣列
//     int **m = malloc((n + 1) * sizeof(int *));
//     int **s = malloc((n + 1) * sizeof(int *));
//     for (int i = 0; i <= n; ++i)
//     {
//         m[i] = malloc((n + 1) * sizeof(int));
//         s[i] = malloc((n + 1) * sizeof(int));
//     }

//     // 計算最小乘法次數
//     matrix_chain_order(dims, n, m, s);
//     printf("最小標量乘法次數: %d\n", m[1][n]);

//     // 使用最佳順序計算矩陣乘積
//     float *result = matrix_chain_multiply(matrices, dims, 1, n, s);

//     // 輸出結果矩陣
//     int final_rows = dims[0];
//     int final_cols = dims[n];

//     // 針對所有測試案例，使用矩陣格式輸出 (每行包含該行的所有元素，以空格分隔)
//     for (int i = 0; i < final_rows; ++i)
//     {
//         for (int j = 0; j < final_cols; ++j)
//         {
//             // 使用 %.0f 格式輸出整數，而非使用無條件捨去
//             printf("%.0f", result[i * final_cols + j]);
//             if (j < final_cols - 1)
//                 printf(" ");
//         }
//         printf("\n");
//     }

//     // 釋放記憶體
//     free(result);
//     for (int i = 1; i <= n; ++i)
//         free(matrices[i]);
//     free(matrices);
//     free(dims);

//     // 釋放 DP 陣列的記憶體
//     for (int i = 0; i <= n; ++i)
//     {
//         free(m[i]);
//         free(s[i]);
//     }
//     free(m);
//     free(s);

//     return 0;
// }
