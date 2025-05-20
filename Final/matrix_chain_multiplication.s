.text
.globl matrix_chain_multiplication

matrix_chain_multiplication:
    addi sp, sp, -2048
    sw ra, 0(sp)

    mv s0, a0    # s0 = matrices
    mv s1, a1    # s1 = rows
    mv s2, a2    # s2 = cols
    mv s3, a3    # s3 = count = N

    li s4, 0     # i = 0
fill_diagonal:
    bge s4, s3, finish_fill_diag
    slli t0, s4, 6
    add t1, sp, t0
    li t2, 0
    sw t2, 0(t1)
    addi s4, s4, 1
    j fill_diagonal
finish_fill_diag:

    li s5, 2     # chain length L
outer_loop:
    bgt s5, s3, done_dp
    li s6, 0     # i = 0
inner_i_loop:
    sub t0, s3, s5
    bgt s6, t0, next_L
    add s7, s6, s5
    addi s7, s7, -1  # j = i + L - 1

    li t1, 0x7fffffff
    slli t2, s6, 6
    add t2, sp, t2
    slli t3, s7, 2
    add t2, t2, t3
    sw t1, 0(t2)     # m[i][j] = INF

    mv s8, s6        # k = i
k_loop:
    beq s8, s7, end_k_loop

    # m[i][k]
    slli t0, s6, 6
    add t0, sp, t0
    slli t1, s8, 2
    add t0, t0, t1
    lw t2, 0(t0)

    # m[k+1][j]
    addi t3, s8, 1
    slli t4, t3, 6
    add t4, sp, t4
    slli t5, s7, 2
    add t4, t4, t5
    lw t3, 0(t4)

    # rows[i]
    slli t0, s6, 2
    add t0, s1, t0
    lw t4, 0(t0)

    # rows[k+1]
    addi t0, s8, 1
    slli t0, t0, 2
    add t0, s1, t0
    lw t5, 0(t0)

    # cols[j]
    slli t0, s7, 2
    add t0, s2, t0
    lw t6, 0(t0)

    mul t4, t4, t5
    mul t4, t4, t6       # cost = rows[i] * rows[k+1] * cols[j]
    add s9, t2, t3
    add s9, s9, t4       # total = m[i][k] + m[k+1][j] + cost

    # compare with current m[i][j]
    slli t0, s6, 6
    add t0, sp, t0
    slli t1, s7, 2
    add t0, t0, t1
    lw t2, 0(t0)
    bge t2, s9, update_m_s
    j skip_update
update_m_s:
    sw s9, 0(t0)
    # s[i][j] = k
    addi t0, sp, 1024
    slli t1, s6, 6
    add t0, t0, t1
    slli t2, s7, 2
    add t0, t0, t2
    sw s8, 0(t0)
skip_update:
    addi s8, s8, 1
    j k_loop
end_k_loop:
    addi s6, s6, 1
    j inner_i_loop
next_L:
    addi s5, s5, 1
    j outer_loop
done_dp:

    li a0, 0
    addi a1, s3, -1
    mv a2, s0      # matrices
    mv a3, s1      # rows
    mv a4, s2      # cols
    addi a5, sp, 1024  # s_table
    jal ra, multiply_chain	# Call multiply_chain
    mv a0, a0      # result pointer returned in a0

    lw ra, 0(sp)
    addi sp, sp, 2047
	addi sp, sp, 1
    jr ra

multiply_chain:
    addi sp, sp, -32
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    beq a0, a1, base_case

    mv s0, a0    # i
    mv s1, a1    # j

    mv t0, a5
    slli t1, s0, 6
    add t0, t0, t1
    slli t2, s1, 2
    add t0, t0, t2
    lw t3, 0(t0)   # k = s[i][j]

    # Left = multiply_chain(i, k)
    mv a0, s0
    mv a1, t3
    mv a2, a2
    mv a3, a3
    mv a4, a4
    mv a5, a5
    jal ra, multiply_chain
    mv s2, a0      # left_matrix_ptr

    # Right = multiply_chain(k+1, j)
    addi a0, t3, 1
    mv a1, s1
    mv a2, a2
    mv a3, a3
    mv a4, a4
    mv a5, a5
    jal ra, multiply_chain
    mv t6, a0      # right_matrix_ptr

    # Allocate result matrix of rows[i] × cols[j]
    slli t0, s0, 2
    add t0, a3, t0
    lw t1, 0(t0)      # rows[i]
    slli t2, s1, 2
    add t2, a4, t2
    lw t3, 0(t2)      # cols[j]
    mul t4, t1, t3
    slli a0, t4, 2
    #li a7, 93
    #ecall
    mv t5, a0        # result pointer

    # Multiply Left (s2) × Right (t6) into Result (t5)
    mv s3, t1      # M = rows[i]
    mv s4, t3      # N = cols[j]

    slli t0, t3, 2 # t0 = N*4 (col step)
    slli t1, t1, 2 # t1 = M*4 (row step)
    
    # rows[k+1]
    slli t2, t3, 2
    add t2, a3, t2
    lw s5, 0(t2)   # K = rows[k+1]

    li s6, 0       # x = 0
loop_x:
    bge s6, s3, done_matmul
    li s7, 0       # y = 0
loop_y:
    bge s7, s4, next_x

    # result[x*N + y] = 0
    mul t2, s6, s4     # x * N
    add t2, t2, s7     # + y
    slli t2, t2, 2     # offset in bytes
    add t3, t5, t2     # address of result[x*N + y]
    li t4, 0
    sw t4, 0(t3)

    li s8, 0       # z = 0
loop_z:
    bge s8, s5, next_y

    # A[x*K + z]
    mul t0, s6, s5
    add t0, t0, s8
    slli t0, t0, 2
    add t1, s2, t0
    lw t2, 0(t1)

    # B[z*N + y]
    mul t0, s8, s4
    add t0, t0, s7
    slli t0, t0, 2
    add t1, t6, t0
    lw t3, 0(t1)

    mul t4, t2, t3

    # result[x*N + y] += t4
    mul t0, s6, s4
    add t0, t0, s7
    slli t0, t0, 2
    add t1, t5, t0
    lw t2, 0(t1)
    add t2, t2, t4
    sw t2, 0(t1)

    addi s8, s8, 1
    j loop_z
next_y:
    addi s7, s7, 1
    j loop_y
next_x:
    addi s6, s6, 1
    j loop_x
done_matmul:

    # Store result pointer in a0
    mv a0, t5

    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 32
    jr ra

base_case:
    slli t0, a0, 2
    add t0, a2, t0
    lw a0, 0(t0)
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 32
    jr ra
