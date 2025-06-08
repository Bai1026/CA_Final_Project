.text
.globl matrix_multiply
.globl matrix_chain_multiplication
.globl malloc

# 矩陣鏈乘法主函式
# a0 = matrices (int **), a1 = rows (int *), a2 = cols (int *), a3 = count (int)
# 返回值: a0 = 結果矩陣指標 (int *)
matrix_chain_multiplication:
    # 保存暫存器到堆疊 (確保 16 位元組對齊)
    addi sp, sp, -48
    sw ra, 44(sp)
    sw s0, 40(sp)
    sw s1, 36(sp)
    sw s2, 32(sp)
    sw s3, 28(sp)
    sw s4, 24(sp)
    sw s5, 20(sp)
    sw s6, 16(sp)
    sw s7, 12(sp)
    sw s8, 8(sp)
    sw s9, 4(sp)
    
    mv s0, a0               # s0 = matrices
    mv s1, a1               # s1 = rows
    mv s2, a2               # s2 = cols
    mv s3, a3               # s3 = count
    
    # 檢查輸入參數是否有效
    beqz s3, error_exit     # if count == 0, 錯誤
    beqz s0, error_exit     # if matrices == NULL, 錯誤
    beqz s1, error_exit     # if rows == NULL, 錯誤
    beqz s2, error_exit     # if cols == NULL, 錯誤
    
    # 如果只有一個矩陣，直接返回該矩陣的複製
    li t0, 1
    bne s3, t0, multiple_matrices
    
    # 複製單一矩陣
    lw s4, 0(s0)            # s4 = matrices[0]
    beqz s4, error_exit     # 檢查矩陣指標是否有效
    lw s5, 0(s1)            # s5 = rows[0]
    lw s6, 0(s2)            # s6 = cols[0]
    
    # 檢查維度是否有效
    blez s5, error_exit     # if rows <= 0, 錯誤
    blez s6, error_exit     # if cols <= 0, 錯誤
    
    mul s7, s5, s6          # s7 = rows[0] * cols[0]
    slli a0, s7, 2          # a0 = size in 位元組
    
    # 呼叫 C malloc 函式
    jal malloc
    beqz a0, error_exit     # 檢查分配是否成功
    mv s8, a0               # s8 = 新矩陣地址
    
    # 複製資料
    mv t0, zero             # i = 0
    slli s7, s7, 2          # s7 = total bytes
copy_loop:
    bge t0, s7, copy_done
    add t1, s4, t0          # source address
    lw t2, 0(t1)            # 載入來源資料
    add t3, s8, t0          # dest address  
    sw t2, 0(t3)            # 儲存到目標
    addi t0, t0, 4          # i += 4
    j copy_loop
    
copy_done:
    mv a0, s8               # 返回結果
    j chain_mult_end
    
multiple_matrices:
    # 處理多個矩陣的情況 - 從左到右依序相乘
    lw s4, 0(s0)            # s4 = matrices[0] (當前結果矩陣)
    beqz s4, error_exit     # 檢查矩陣指標是否有效
    lw s5, 0(s1)            # s5 = rows[0] (當前結果行數)
    
    # 檢查維度是否有效
    blez s5, error_exit     # if rows <= 0, 錯誤
    
    # 先複製第一個矩陣作為初始結果
    lw s6, 0(s2)            # s6 = cols[0]
    mul s7, s5, s6          # s7 = rows[0] * cols[0]
    slli a0, s7, 2          # a0 = size in 位元組
    
    # 呼叫 C malloc 函式
    jal malloc
    beqz a0, error_exit     # 檢查分配是否成功
    mv s4, a0               # s4 = 新的結果矩陣
    
    # 複製第一個矩陣的資料
    lw s8, 0(s0)            # s8 = matrices[0]
    mv t0, zero             # i = 0
    slli s7, s7, 2          # s7 = total bytes
copy_first_matrix:
    bge t0, s7, first_copy_done
    add t1, s8, t0          # source address
    lw t2, 0(t1)            # 載入來源資料
    add t3, s4, t0          # dest address
    sw t2, 0(t3)            # 儲存到目標
    addi t0, t0, 4          # i += 4
    j copy_first_matrix
    
first_copy_done:
    li s8, 1                # i = 1
mult_loop:
    bge s8, s3, mult_done   # if i >= count, 結束
    
    # 取得下一個矩陣
    slli t0, s8, 2          # t0 = i * 4
    add t0, s0, t0          # t0 = &matrices[i]
    lw s9, 0(t0)            # s9 = matrices[i]
    beqz s9, error_exit     # 檢查矩陣指標是否有效
    
    # 取得維度
    slli t1, s8, 2          # t1 = i * 4
    add t1, s2, t1          # t1 = &cols[i]
    lw s6, -4(t1)           # s6 = cols[i-1] (共同維度)
    lw s7, 0(t1)            # s7 = cols[i] (結果列數)
    
    # 檢查維度是否有效
    blez s6, error_exit     # if n <= 0, 錯誤
    blez s7, error_exit     # if l <= 0, 錯誤
    
    # 分配結果矩陣
    mul t2, s5, s7          # t2 = rows * cols
    slli a0, t2, 2          # a0 = size in 位元組
    
    # 呼叫 C malloc 函式
    jal malloc
    beqz a0, error_exit     # 檢查分配是否成功
    
    # 保存結果矩陣地址
    sw a0, 0(sp)            # 暫存結果矩陣地址
    
    # 執行矩陣乘法
    mv a2, a0               # a2 = 結果矩陣
    mv a0, s4               # a0 = 左矩陣
    mv a1, s9               # a1 = 右矩陣
    mv a3, s5               # a3 = m (左矩陣行數)
    mv a4, s6               # a4 = n (共同維度)
    mv a5, s7               # a5 = l (右矩陣列數)
    jal matrix_multiply
    
    # 恢復結果矩陣地址並更新當前結果
    lw s4, 0(sp)            # s4 = 新的結果矩陣
    # s5 保持不變 (行數)
    
    addi s8, s8, 1          # i++
    j mult_loop
    
mult_done:
    mv a0, s4               # 返回最終結果
    j chain_mult_end
    
error_exit:
    mv a0, zero             # 返回 NULL
    
chain_mult_end:
    lw s9, 4(sp)
    lw s8, 8(sp)
    lw s7, 12(sp)
    lw s6, 16(sp)
    lw s5, 20(sp)
    lw s4, 24(sp)
    lw s3, 28(sp)
    lw s2, 32(sp)
    lw s1, 36(sp)
    lw s0, 40(sp)
    lw ra, 44(sp)
    addi sp, sp, 48
    jr ra

# 矩陣乘法函式: matrix_multiply(int *A, int *B, int *C, int m, int n, int l)
# a0 = A矩陣指標, a1 = B矩陣指標, a2 = C矩陣指標
# a3 = m (A的行數), a4 = n (A的列數/B的行數), a5 = l (B的列數)
matrix_multiply:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)
    
    # 檢查輸入參數
    beqz a0, mult_error     # if A == NULL, 錯誤
    beqz a1, mult_error     # if B == NULL, 錯誤
    beqz a2, mult_error     # if C == NULL, 錯誤
    blez a3, mult_error     # if m <= 0, 錯誤
    blez a4, mult_error     # if n <= 0, 錯誤
    blez a5, mult_error     # if l <= 0, 錯誤
    
    mv s0, a0               # s0 = A
    mv s1, a1               # s1 = B
    mv s2, a2               # s2 = C
    mv s3, a3               # s3 = m
    mv s4, a4               # s4 = n
    mv s5, a5               # s5 = l
    
    li t0, 0                # i = 0 (外層迴圈計數器)
    
outer_loop:
    bge t0, s3, end_outer   # if i >= m, 結束外層迴圈
    li t1, 0                # j = 0 (中層迴圈計數器)
    
middle_loop:
    bge t1, s5, end_middle  # if j >= l, 結束中層迴圈
    
    # 計算 C[i][j] 的地址
    mul t2, t0, s5          # t2 = i * l
    add t2, t2, t1          # t2 = i * l + j
    slli t2, t2, 2          # t2 = (i * l + j) * 4 (位元組偏移)
    add t2, s2, t2          # t2 = C + 偏移量
    
    sw zero, 0(t2)          # C[i][j] = 0
    
    li t3, 0                # k = 0 (內層迴圈計數器)
    
inner_loop:
    bge t3, s4, end_inner   # if k >= n, 結束內層迴圈
    
    # 計算 A[i][k] 的地址
    mul t4, t0, s4          # t4 = i * n
    add t4, t4, t3          # t4 = i * n + k
    slli t4, t4, 2          # t4 = (i * n + k) * 4
    add t4, s0, t4          # t4 = A + 偏移量
    lw t4, 0(t4)            # t4 = A[i][k]
    
    # 計算 B[k][j] 的地址
    mul t5, t3, s5          # t5 = k * l
    add t5, t5, t1          # t5 = k * l + j
    slli t5, t5, 2          # t5 = (k * l + j) * 4
    add t5, s1, t5          # t5 = B + 偏移量
    lw t5, 0(t5)            # t5 = B[k][j]
    
    # 計算 A[i][k] * B[k][j]
    mul t6, t4, t5          # t6 = A[i][k] * B[k][j]
    
    # C[i][j] += A[i][k] * B[k][j]
    lw t4, 0(t2)            # 載入 C[i][j]
    add t4, t4, t6          # C[i][j] += 乘積
    sw t4, 0(t2)            # 儲存回 C[i][j]
    
    addi t3, t3, 1          # k++
    j inner_loop
    
end_inner:
    addi t1, t1, 1          # j++
    j middle_loop
    
end_middle:
    addi t0, t0, 1          # i++
    j outer_loop
    
end_outer:
    j mult_end
    
mult_error:
    # 錯誤處理
    nop
    
mult_end:
    # 恢復暫存器
    lw s5, 4(sp)
    lw s4, 8(sp)
    lw s3, 12(sp)
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    jr ra