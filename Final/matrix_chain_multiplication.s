.text
.globl matrix_chain_multiplication
.globl malloc


#	a0: matrices, int**
#	a1: rows, 	int*
#	a2: cols,	int*
#	a3: count,	int

matrix_chain_multiplication:
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

	addi s0, a3, 1		#	s0 = n+1
	addi s1, zero, 0
	addi s2, zero, 0
	addi s3, zero, 0
	addi a1, a1, -4		#	shift elements in a1 right by 1, first element = a1[1]
	addi a2, a2, -4		#	shift elements in a2 right by 1 
	addi sp, sp, -1088	#	table m, m[i, j] = (i*16+j)*4
	mv t0, sp
	mv a7, a0			#	a7 = matrix value address
init_tablem:
	addi s1, s1, 1
	slli s2, s1, 4
	add s3, s1, s2
	slli s3, s3, 2
	add t0, sp, s3
	sw zero, 0(t0)
	bne s1, a3, init_tablem
	
	mv t0, sp			#	t0 = table m address
	addi sp, sp, -1088	#	table s
	li t2, 0x7fffffff	#	t2 = max number	
	mv t1, sp			#	t1 = table s address
	
start_DP:
	addi s1, zero, 2	#	s1 = l
DP_outer:
	addi s2, zero, 1	#	s2 = i = 1
DP_inter:
	sub a4, a3, s1
	addi a4, a4, 2		#	a4 = n-l+2
	add s3, s1, s2
	addi s3, s3, -1		#	s3 = j = i+l-1
	slli s4, s2, 4
	add s4, s4, s3
	slli s4, s4, 2		#	s4 = [i, j] offset
	add t5, t0, s4		#	t5 = m[i, j] address
	sw t2, 0(t5)
	add s4, zero, s2		#	s4 = k
DP_inner:
	slli s5, s2, 4
	add s5, s5, s4
	slli s5, s5, 2		#	s5 = [i, k] offset
	addi s6, s4, 1
	slli s6, s6, 4
	add s6, s6, s3
	slli s6, s6, 2		#	s6 = [k+1, j] offset
	add t3, t0, s5
	add t4, t0, s6
	lw s5, 0(t3)		#	s5 = m[i, k]
	lw s6, 0(t4)		#	s6 = m[k+1, j]
	slli s7, s2, 2		#	s7 = i offset
	slli s8, s4, 2		#	s8 = k offset
	slli s9, s3, 2		#	s9 = j offset
	add s10, a2, s8
	add s11, a2, s9	
	lw s8, 0(s10)		#	s8 = p_k
	lw s9, 0(s11)		#	s9 = p_j
	add s10, a1, s7
	lw s7, 0(s10)		#	s7 = p_i-1
	mul s7, s7, s8
	mul s7, s7, s9		#	s7 = p_i-1*p_k*p_j
	add s6, s6, s7
	add s5, s5, s6		#	s5 = q
	lw s8, 0(t5)		#	s8 = m[i, j]
	
	slt s6, s5, s8
	beq s6, x0, else_q	#	if q < m[i, j]:
	addi t6, t5, -1088	#		t6 = s[i, j] address
	sw s5, 0(t5)		#		m[i, j] = q
	sw s4, 0(t6)		#		s[i, j] = k
	
else_q:
	addi s4, s4, 1
	bne s4, s3, DP_inner

	addi s2, s2, 1
	bne s2, a4, DP_inter
	
	addi s1, s1, 1
	bne s1, s0, DP_outer
	
end_DP:
	addi s0, x0, 1		#	s0 = i = 1
	add s1, x0, a3		#	s1 = j = n
	addi s2, x0, 0		#	s2 = left matrix address
	addi s3, x0, 0		#	s3 = right matrix address
	addi s4, x0, 0		#	s4 = row[left] 
	addi s5, x0, 0		#	s5 = col[left] = row[right]
	addi s6, x0, 0		#	s6 = col[right]
	mv t1, sp			#	t1 = table s address = original sp-2176
	#addi a1, a1, 4		#	a1: rows, 	int*
	#addi a2, a2, 4		#	a2: cols,	int*
						#	a3: count,	int
	addi a7, a7, -4		#	a7: matrices, int**

	jal ra, optimal_order
	
	addi sp, sp, 1088
	addi sp, sp, 1088
	mv a0, s2
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

##########################################################################################################################

optimal_order:
	addi sp, sp, -32
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)		
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw ra, 28(sp)
	
	beq s0, s1, matrix_found
	
find_L:
	slli t3, s0, 4
	add t3, t3, s1
	slli t3, t3, 2		#	t3 = [i, j] offset
	add t3, t1, t3
	lw s1, 0(t3)		#	s1 = s[i, j]
	jal ra, optimal_order
	#sw s2, 8(sp)
find_R:
	mv s0, s1			#	s0 = s[i, j]
	lw s1, 4(sp)		#	s1 = j
	addi s0, s0, 1		#	s0 = s[i, j]+1
	jal ra, optimal_order
	lw s0, 0(sp)		#	s0 = i
	#lw s2, 8(sp)
	lw ra, 28(sp)

multiply_matrices:
	mul a0, s4, s6
	slli a0, a0, 2
	call malloc
	mv t0, a0			#	t0 = result address (ori t5)
						# 	s4 = m = rows[left] (ori s3)
						# 	s5 = n = cols[left] = rows[right] (ori s4)
						# 	s6 = l = cols[right] (ori s5)

    li t4, 0       		#	t4 = x = 0 (ori s6)
loop_x:
    bge t4, s4, end_x	#	if x == row[left]:	done
    li t5, 0       		# 	t5 = y = 0 (ori s7)
loop_y:
    bge t5, s6, end_y	#	if y == col[right]: end_y

    #	Initialize result[x*l + y] = 0
    mul a0, t4, s6     	# 	a0 = x * l
    add a0, a0, t5     	# 	a0 += y
    slli a0, a0, 2     	# 	byte offset
    add a0, t0, a0     	# 	result[x][y] address
    sw zero, 0(a0)		#	result[x][y] = 0

    li t6, 0           	# 	t6 = z = 0 (ori s8)
loop_z:
    bge t6, s5, end_z	#	if z == row[k+1]:	end_z

    # 	left[x*n+z]
    mul a4, t4, s5     	# 	a4 = x*n (ori t0)
    add a4, a4, t6		#	a4 = x*n+z
    slli a4, a4, 2
    add a4, s2, a4		#	a4 = left[x][z] address
    lw a4, 0(a4)       	# 	a4 = left[x][z]

    # 	right[z*l+y]
    mul a5, t6, s6
    add a5, a5, t5
    slli a5, a5, 2
    add a5, s3, a5
    lw a5, 0(a5)       	# 	a5 = right[z][y]

    mul a6, a4, a5     	# 	a6 = left[x][z]*right[z][y]

    # 	result[x][y] += A[x][z] * B[z][y]
	lw a4, 0(a0)		#	load result[x][y]
	add a4, a4, a6		#	result[x][y] += a6
	sw a4, 0(a0)		#	write back

    addi t6, t6, 1		#	z++
    j loop_z

end_z:
    addi t5, t5, 1		#	y++
    j loop_y

end_y:
    addi t4, t4, 1		#	x++
    j loop_x

end_x:
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)		
	lw s3, 12(sp)
	lw ra, 28(sp)

    #	Store result pointer
	#beq s3, zero, store_right
	beq s2, zero, store_left
store_right:
	mv s3, t0
	mv s5, s4
	lw s4, 16(sp)
	addi sp, sp, 32
	jr ra
store_left:
    mv s2, t0
	mv s5, s6
	lw s6, 24(sp)
	addi sp, sp, 32
	jr ra
	
matrix_found:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)		
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw ra, 28(sp)
	addi sp, sp, 32

	#slli t3, s0, 2		#	t3 = i offset
	#addi t3, s0, -1
	slli t3, s0, 2
	beq s2, x0, L_found
R_found:
	add s6, a2, t3		#	s6 be address of col[right]
	add s3, a7, t3		#	s3 = address of right matrix
	lw s6, 0(s6)		#	s6 = col[right]
	jr ra
L_found:
	add s2, a7, t3		#	s2 = address of left matrix
	add s4, a1, t3		#	s4 be address of row[left]
	add s5, a2, t3		#	s5 be address of col[left]
	lw s4, 0(s4)		#	s4 = row[left]
	lw s5, 0(s5)		#	s5 = col[left]
	jr ra
