.text
.globl matrix_chain_multiplication

matrix_chain_multiplication:
    # 保存重要暫存器
    addi sp, sp, -40
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    sw s8, 36(sp)
    
    # 將參數保存到保留暫存器中
    mv s0, a0      # s0 = matrices
    mv s1, a1      # s1 = rows
    mv s2, a2      # s2 = cols
    mv s3, a3      # s3 = count
    
    # 動態配置記憶體給 dp 表格 (count x count)
    li t0, 4       # 每個元素 4 位元組 (32-bit integers)
    mul a0, s3, s3 # count * count
    mul a0, a0, t0 # count * count * 4
    jal ra, malloc
    mv s4, a0      # s4 = dp 表格
    
    # 動態配置記憶體給 brackets 表格 (用於保存最佳括號位置)
    li t0, 4
    mul a0, s3, s3
    mul a0, a0, t0
    jal ra, malloc
    mv s5, a0      # s5 = brackets 表格

    # 初始化 dp 表格
    mv t0, s4      # t0 = dp 表格起始位址
    li t1, 0       # t1 = 0, 迴圈計數器
    mul t2, s3, s3 # t2 = count * count, 總元素數量
init_dp_loop:
    beq t1, t2, init_dp_done
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 1
    j init_dp_loop
init_dp_done:

    # 初始化對角線元素為 0 (dp[i][i] = 0)
    li t0, 0       # t0 = i
diag_loop:
    beq t0, s3, diag_done
    mul t1, t0, s3 # t1 = i * count
    add t1, t1, t0 # t1 = i * count + i
    slli t1, t1, 2 # t1 = (i * count + i) * 4
    add t1, t1, s4 # t1 = dp + (i * count + i) * 4
    sw zero, 0(t1) # dp[i][i] = 0
    addi t0, t0, 1
    j diag_loop
diag_done:

    # 動態規劃求解最佳矩陣鏈相乘順序
    li s6, 1       # s6 = len (鏈長度)
len_loop:
    beq s6, s3, len_done
    li t0, 0       # t0 = i (起始矩陣索引)
i_loop:
    add t1, t0, s6 # t1 = j = i + len
    bge t1, s3, i_done
    
    # dp[i][j] = min{dp[i][k] + dp[k+1][j] + rows[i] * cols[k] * cols[j]}
    mul t2, t0, s3    # t2 = i * count
    add t2, t2, t1    # t2 = i * count + j
    slli t2, t2, 2    # t2 = (i * count + j) * 4
    add t2, t2, s4    # t2 = &dp[i][j]
    
    li t3, -1         # t3 = 初始最小值設為 -1 (表示還沒找到)
    mv s7, t0         # s7 = k
k_loop:
    beq s7, t1, k_done
    
    # 計算 dp[i][k]
    mul t5, t0, s3    # t5 = i * count
    add t5, t5, s7    # t5 = i * count + k
    slli t5, t5, 2    # t5 = (i * count + k) * 4
    add t5, t5, s4    # t5 = &dp[i][k]
    lw t5, 0(t5)      # t5 = dp[i][k]
    
    # 計算 dp[k+1][j]
    addi t6, s7, 1    # t6 = k + 1
    mul t6, t6, s3    # t6 = (k + 1) * count
    add t6, t6, t1    # t6 = (k + 1) * count + j
    slli t6, t6, 2    # t6 = ((k + 1) * count + j) * 4
    add t6, t6, s4    # t6 = &dp[k+1][j]
    lw t6, 0(t6)      # t6 = dp[k+1][j]
    
    # 計算 rows[i] * cols[k] * cols[j]
    slli t4, t0, 2    # t4 = i * 4
    add t4, t4, s1    # t4 = &rows[i]
    lw a0, 0(t4)      # a0 = rows[i]
    
    slli t4, s7, 2    # t4 = k * 4
    add t4, t4, s2    # t4 = &cols[k]
    lw a1, 0(t4)      # a1 = cols[k]
    
    mul a0, a0, a1    # a0 = rows[i] * cols[k]
    
    slli t4, t1, 2    # t4 = j * 4
    add t4, t4, s2    # t4 = &cols[j]
    lw a1, 0(t4)      # a1 = cols[j]
    
    mul a0, a0, a1    # a0 = rows[i] * cols[k] * cols[j]
    
    # 計算 cost = dp[i][k] + dp[k+1][j] + rows[i] * cols[k] * cols[j]
    add a0, a0, t5    # a0 = rows[i] * cols[k] * cols[j] + dp[i][k]
    add a0, a0, t6    # a0 = rows[i] * cols[k] * cols[j] + dp[i][k] + dp[k+1][j]
    
    # 如果 cost < min_cost 或 min_cost 還沒設定
    li t5, -1
    beq t3, t5, update_min
    blt a0, t3, update_min
    j skip_update
update_min:
    mv t3, a0         # 更新最小 cost
    
    # 更新 brackets[i][j] = k
    mul t5, t0, s3    # t5 = i * count
    add t5, t5, t1    # t5 = i * count + j
    slli t5, t5, 2    # t5 = (i * count + j) * 4
    add t5, t5, s5    # t5 = &brackets[i][j]
    sw s7, 0(t5)      # brackets[i][j] = k
skip_update:
    addi s7, s7, 1    # k++
    j k_loop
k_done:
    
    # 存儲 dp[i][j] = min_cost
    sw t3, 0(t2)
    
    addi t0, t0, 1    # i++
    j i_loop
i_done:
    addi s6, s6, 1    # len++
    j len_loop
len_done:

    # 根據 brackets 表格計算最終結果矩陣
    li a0, 0          # i = 0
    addi a1, s3, -1   # j = count - 1
    mv a2, s5         # brackets 表格
    jal ra, compute_matrix
    mv s8, a0         # s8 = 結果矩陣

    # 釋放 dp 表格記憶體
    mv a0, s4
    jal ra, free
    
    # 釋放 brackets 表格記憶體
    mv a0, s5
    jal ra, free
    
    # 返回結果矩陣
    mv a0, s8
    
    # 恢復暫存器
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    lw s8, 36(sp)
    addi sp, sp, 40
    
    jr ra

# 輔助函式：計算矩陣鏈 [i...j] 的結果
# a0 = i, a1 = j, a2 = brackets 表格
# 返回：a0 = 計算結果矩陣
compute_matrix:
    # 保存暫存器
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    mv s0, a0      # s0 = i
    mv s1, a1      # s1 = j
    mv s2, a2      # s2 = brackets
    # 需要主函式傳遞 count 參數
    # 使用任一可用暫存器 (比如a3) 傳遞 count 參數
    mv s3, a3      # s3 = count (需新增)
    
    # 如果 i == j，直接返回 matrices[i]
    bne s0, s1, not_single
    # 修正：正確計算 matrices[i] 的位址
    # 假設 matrices 是指標陣列，每個元素為 4 位元組
    slli t0, s0, 2    # t0 = i * 4
    add t0, t0, s0_original_matrix_ptr  # 使用正確的矩陣基址 (傳入參數)
    lw a0, 0(t0)      # a0 = matrices[i]
    j compute_done
not_single:
    # 獲取 k = brackets[i][j]
    mul t0, s0, s3    # t0 = i * count
    add t0, t0, s1    # t0 = i * count + j
    slli t0, t0, 2    # t0 = (i * count + j) * 4
    add t0, t0, s2    # t0 = &brackets[i][j]
    lw t0, 0(t0)      # t0 = k
    
    # 遞歸計算左子矩陣 (i, k)
    mv a0, s0
    mv a1, t0
    mv a2, s2
    mv a3, s3         # 傳遞 count 參數
    mv a4, s0_original_matrix_ptr # 傳遞原始矩陣指標
    jal ra, compute_matrix
    mv t1, a0         # t1 = 左子矩陣
    
    # 遞歸計算右子矩陣 (k+1, j)
    addi a0, t0, 1
    mv a1, s1
    mv a2, s2
    mv a3, s3         # 傳遞 count 參數
    mv a4, s0_original_matrix_ptr # 傳遞原始矩陣指標
    jal ra, compute_matrix
    mv t2, a0         # t2 = 右子矩陣
    
    # 矩陣乘法：t1 * t2
    # 獲取左矩陣的維度
    slli t3, s0, 2    # t3 = i * 4
    add t3, t3, s1    # t3 = &rows[i]
    lw a0, 0(t3)      # a0 = 左矩陣的列數
    
    slli t3, t0, 2    # t3 = k * 4
    add t3, t3, s2    # t3 = &cols[k]
    lw a1, 0(t3)      # a1 = 左矩陣的行數
    
    # 獲取右矩陣的維度
    addi t4, t0, 1    # t4 = k + 1
    slli t4, t4, 2    # t4 = (k + 1) * 4
    add t4, t4, s1    # t4 = &rows[k+1]
    lw a2, 0(t4)      # a2 = 右矩陣的列數
    
    slli t4, s1, 2    # t4 = j * 4
    add t4, t4, s2    # t4 = &cols[j]
    lw a3, 0(t4)      # a3 = 右矩陣的行數
    
    # 呼叫矩陣乘法
    mv a4, t1         # a4 = 左矩陣
    mv a5, t2         # a5 = 右矩陣
    jal ra, matrix_multiply
    
compute_done:
    # 恢復暫存器
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    
    jr ra

# 矩陣乘法函式
# a0 = 左矩陣的列數
# a1 = 左矩陣的行數/右矩陣的列數
# a3 = 右矩陣的行數
# a4 = 左矩陣
# a5 = 右矩陣
# 返回：a0 = 結果矩陣
matrix_multiply:
    # 保存暫存器
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    
    mv s0, a0      # s0 = 左矩陣的列數
    mv s1, a1      # s1 = 左矩陣的行數/右矩陣的列數
    mv s2, a3      # s2 = 右矩陣的行數
    mv s3, a4      # s3 = 左矩陣
    mv s4, a5      # s4 = 右矩陣
    
    # 分配結果矩陣記憶體 (s0 x s2)
    mul a0, s0, s2    # a0 = 左矩陣的列數 * 右矩陣的行數
    slli a0, a0, 2    # 每個元素 4 位元組
    jal ra, malloc
    mv t0, a0         # t0 = 結果矩陣
    
    # 實作矩陣乘法
    li t1, 0          # t1 = i (列迴圈)
i_mult_loop:
    beq t1, s0, i_mult_done
    li t2, 0          # t2 = j (行迴圈)
j_mult_loop:
    beq t2, s2, j_mult_done
    
    li t3, 0          # t3 = 累積和
    li t4, 0          # t4 = k (內層迴圈)
k_mult_loop:
    beq t4, s1, k_mult_done
    
    # 計算左矩陣元素位址 (i, k)
    mul t5, t1, s1    # t5 = i * left_cols
    add t5, t5, t4    # t5 = i * left_cols + k
    slli t5, t5, 2    # t5 = (i * left_cols + k) * 4
    add t5, t5, s3    # t5 = left + (i * left_cols + k) * 4
    lw t5, 0(t5)      # t5 = left[i][k]
    
    # 計算右矩陣元素位址 (k, j)
    mul t6, t4, s2    # t6 = k * right_cols
    add t6, t6, t2    # t6 = k * right_cols + j
    slli t6, t6, 2    # t6 = (k * right_cols + j) * 4
    add t6, t6, s4    # t6 = right + (k * right_cols + j) * 4
    lw t6, 0(t6)      # t6 = right[k][j]
    
    # 累積乘積
    mul t6, t5, t6    # t6 = left[i][k] * right[k][j]
    add t3, t3, t6    # t3 += left[i][k] * right[k][j]
    
    addi t4, t4, 1    # k++
    j k_mult_loop
k_mult_done:
    
    # 儲存結果
    mul t4, t1, s2    # t4 = i * result_cols
    add t4, t4, t2    # t4 = i * result_cols + j
    slli t4, t4, 2    # t4 = (i * result_cols + j) * 4
    add t4, t4, t0    # t4 = result + (i * result_cols + j) * 4
    sw t3, 0(t4)      # result[i][j] = sum
    
    addi t2, t2, 1    # j++
    j j_mult_loop
j_mult_done:
    addi t1, t1, 1    # i++
    j i_mult_loop
i_mult_done:
    
    mv a0, t0         # 返回結果矩陣
    
    # 恢復暫存器
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    
    jr ra