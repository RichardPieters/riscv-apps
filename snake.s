.data
snakeStartIndex:
    .word -4
snakeLength:
    .word 12 # start length of snake (pixel count * 4)
snakeBufferMaxLength:
    .word 64 # snake pixel count * 4 -> determines buffer size for snake position
berryLocation:
    .half 4,3
weylSequence:
    .word 0xda1ce2a9 # sequence similar to the Weyl sequence; helps reduce repeated random values.
randomSeed:
    .word 234
randomNumber:
    .word 0
snake:
    .zero 12

.text

start:
    li s0 12 # x-pos
    li s1 17 # y-pos
    li s2 0 # direction up, down, left, right
    li s11 0 # timer
    
    jal ra updateSnake
    jal ra updateBerryLocation
main:
    jal ra checkInput
    
    #li s11 0
    beq s11 x0 mainTick
    addi s11 s11 -1
    jal x0 main
    
mainTick:
    jal ra move
    
    jal ra checkForBerry
    
    jal ra drawSnake
    
    li s11 1000 # change to set simulation speed
    jal x0 main
    
checkInput:
    li t4 D_PAD_0_BASE

    li t3 1
    
    lw t5 0, t4
    beq t5 t3 changeDirectionUp
    lw t5 4, t4
    beq t5 t3 changeDirectionDown
    lw t5 8, t4
    beq t5 t3 changeDirectionLeft
    lw t5 12, t4
    beq t5 t3 changeDirectionRight
    
    ret

changeDirectionUp:
    li s2 0
    ret
changeDirectionDown:
    li s2 1
    ret
changeDirectionLeft:
    li s2 2
    ret
changeDirectionRight:
    li s2 3
    ret
    
move:
    li t0 LED_MATRIX_0_BASE
    li t1 LED_MATRIX_0_WIDTH
    li t2 LED_MATRIX_0_HEIGHT

    li t3 0
    
    beq s2 t3 move_up
    addi t3 t3 1
    beq s2 t3 move_down
    addi t3 t3 1
    beq s2 t3 move_left
    addi t3 t3 1
    beq s2 t3 move_right
    
    ret

move_up:
    addi s1 s1 -1
    li t3 0
    bge s1 t3 updateSnake 	# branch if greater or equal
    addi s1 t2 -1
    jal x0 updateSnake

move_right:
    addi s0 s0 1
    addi t3 t1 -1
    ble s0 t3 updateSnake
    addi s0 x0 0
    jal x0 updateSnake

move_down:
    addi s1 s1 1
    addi t3 t2 -1
    ble s1 t3 updateSnake
    addi s1 x0 0
    jal x0 updateSnake

move_left:
    addi s0 s0 -1
    li t3 0
    bge s0 t3 updateSnake 	# branch if greater or equal
    addi s0 t1 -1
    jal x0 updateSnake
move_ret:
    jal x0 updateSnake
    
updateSnake:
    # increment snake index
    lw t1 snakeStartIndex
    addi t1 t1 4
    
    lw t2 snakeBufferMaxLength
    
    bne t1 t2 updateSnake_Branch_DontResetStartIndex # if snakeStartIndex equals to snakeMaxLength, reset it to 0

    # reset start inex
    li t1 0

updateSnake_Branch_DontResetStartIndex:
    la t0 snakeStartIndex
    sw t1 0 t0
    # store current snake head position in snake array
    mv a0 s0
    mv a1 s1
    li a2 0    # location offset 0
    
    addi sp sp -4
    sw ra 0 sp
    jal ra storeLocationInSnakeArray
    lw ra 0 sp
    addi sp sp 4

    ret
    
updateSnake_Branch_ResetStartIndex:
    
drawSnake:
    addi sp sp -4    # push ra
    sw ra 0 sp
    
    # remove last pixel of snake's tail
    lw a0 snakeLength    # location offset is negative length
    not a0 a0
    addi a0 a0 1
       
    jal ra loadLocationFromSnakeArray    # get location in a0 and a1
    
    li a2 0    # color black (erase pixel)
    
    jal ra paintPixel
    
    # paint snake's head in yellow
    mv a0 s0
    mv a1 s1
    
    li a2 0xffff00
    jal ra paintPixel
    
    # check self-collision
    li s10 -4
    lw s9 snakeLength    # location offset is negative length
    not s9 s9
    addi s9 s9 1
    
selfCollisionLoop:
    ble s10 s9 returnFromStack
    
    mv a0 s10
    
    jal ra loadLocationFromSnakeArray
    
    beq a0 s0 collisionFoundFirstCoordinate
    
    addi s10 s10 -4
    jal x0 selfCollisionLoop
    
collisionFoundFirstCoordinate:
    beq a1 s1 collisionFound
    
    addi s10 s10 -4
    jal x0 selfCollisionLoop
    
collisionFound:
    jal x0 end
    
    lw ra 0 sp     # pop ra
    addi sp sp 4
    ret
paintPixel:
    li t1 LED_MATRIX_0_BASE
    li t3 LED_MATRIX_0_WIDTH

    add t0 x0 t3 		# column count
    mul t2 a1 t0 		# y * column count
    add t2 t2 a0 		# + x-coordinate
    addi t0 x0 4 		# size of color entry
    mul t2 t2 t0 		# times offset
    add t2 t2 t1 		# + base adress

    sw a2 0 t2
    ret
loadLocationFromSnakeArray:
    la t0 snake
    lw t1 snakeStartIndex
    add t0 t0 t1
    add t0 t0 a0
    
    la t2 snake
    bge t0 t2 loadLocationInSnakeArray_BranchResume
    
    # handle wraparound when accessing snake array
    lw t2 snakeBufferMaxLength
    add t0 t0 t2
    
    loadLocationInSnakeArray_BranchResume:
    lh a0 0 t0
    addi t0 t0 2
    lh a1 0 t0
    
    ret

storeLocationInSnakeArray:
    la t0 snake
    lw t1 snakeStartIndex
    add t0 t0 t1
    add t0 t0 a2
    
    la t2 snake
    bge t0 t2 storeLocationInSnakeArray_BranchResume
    
    # handle wraparound when accessing snake array
    lw t2 snakeBufferMaxLength
    add t0 t0 t2
    
    storeLocationInSnakeArray_BranchResume:
    sh a0 0 t0
    addi t0 t0 2
    sh a1 0 t0
    
    ret
    
checkForBerry:
    la t0 berryLocation
    lh a0 0 t0
    addi t0 t0 2
    lh a1 0 t0
    
    # draw berry
    addi sp sp -4    # push ra
    sw ra 0 sp
    
    jal ra drawBerry
    
    lw ra 0 sp    # pop ra
    addi sp sp 4
    
    bne s0 a0 return
checkForBerrySecondCoordinate:
    bne s1 a1 return
berryFound:
    la t0 snakeLength
    lw t1 snakeLength
    lw t2 snakeBufferMaxLength
    addi t1 t1 4
    bge t1 t2 updateBerryLocation
    sw t1 0 t0
updateBerryLocation:
    addi sp sp -4    # push ra
    sw ra 0 sp
    
    jal ra calculateRandom5Bits
    mv s10 a0
    jal ra calculateRandom5Bits
    mv a1 a0
    mv a0 s10
    
    lw ra 0 sp    # pop ra
    addi sp sp 4
    
    la t0 berryLocation
    sh a0 0 t0
    addi t0 t0 2
    sh a1 0 t0
drawBerry:
    addi sp sp -4    # push ra
    sw ra 0 sp
    
    # remove last pixel
    li a2 0xff00ff    # color purple
    
    jal ra paintPixel
    
    lw ra 0 sp    # pop ra
    addi sp sp 4
    ret

calculateRandom5Bits:
    # based on https://stackoverflow.com/questions/35583343/generating-random-numbers-in-assembly,
    # but slightly simplified
    lw t0 randomNumber
    lw t1 randomSeed
    lw t2 weylSequence
    li t3 0xffff
    
    mul t0, t0, t0       
    add t2, t2, t1       
    add t0, t0, t2
    srli t0, t0, 8
    and t0 t0 t3
    mv a0 t0
    srli a0 a0 11
    
    la t3 randomNumber
    sw t0 0 t3

    ret
    
return:
    ret
returnFromStack:
    lw ra 0 sp    # pop ra
    addi sp sp 4
    ret
end:
    li a7 10
    ecall
