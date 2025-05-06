.data
prompt:     .asciiz "\nChoose your action:\n1. Slash\n2. Fireball\n3. Heal\n> "
slash_text: .asciiz "You used Slash!\n"
fire_text:  .asciiz "You cast Fireball!\n"
miss_text:  .asciiz "The Fireball missed!\n"
heal_text:  .asciiz "You healed yourself!\n"
boss_text:  .asciiz "Boss attacks!\n"
win_text:   .asciiz "\nYou defeated the Boss!\n"
lose_text:  .asciiz "\nYou died! Game Over.\n"
hp_status:  .asciiz "Your HP: "
boss_status:.asciiz "Boss HP: "
newline:    .asciiz "\n"

.text
.globl main

main:
    li $s0, 100        # player HP
    li $s1, 150        # boss HP
    li $t7, 0          # pseudo-random counter

game_loop:
    # Show status
    li $v0, 4
    la $a0, hp_status
    syscall
    li $v0, 1
    move $a0, $s0
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 4
    la $a0, boss_status
    syscall
    li $v0, 1
    move $a0, $s1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # Player action
    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 5
    syscall
    move $t0, $v0      # user input

    # Slash
    li $t1, 1
    beq $t0, $t1, slash
    # Fireball
    li $t1, 2
    beq $t0, $t1, fireball
    # Heal
    li $t1, 3
    beq $t0, $t1, heal

    j game_loop        # invalid input

slash:
    li $v0, 4
    la $a0, slash_text
    syscall
    li $t2, 15
    sub $s1, $s1, $t2
    j boss_turn

fireball:
    li $v0, 4
    la $a0, fire_text
    syscall

    # Use $time register as a pseudo-random source (better randomness)
    mfhi $t7               # Get high bits of $hi (this comes from the timer)
    andi $t7, $t7, 1       # Random bit: 0 or 1 (50% chance)
    bnez $t7, fire_miss    # If $t7 is 1 (miss)

    li $t2, 25             # Fireball damage
    sub $s1, $s1, $t2      # Apply damage to the boss
    j boss_turn

fire_miss:
    li $v0, 4
    la $a0, miss_text
    syscall
    j boss_turn

heal:
    li $v0, 4
    la $a0, heal_text
    syscall

    # Check if player's HP is already full (100)
    li $t2, 100
    beq $s0, $t2, boss_turn   # If HP is already 100, skip healing

    li $t2, 20                # Heal value
    add $s0, $s0, $t2         # Add healing to player's HP

    # Cap player's HP at 100
    li $t3, 100
    bgt $s0, $t3, cap_hp

    j boss_turn

cap_hp:
    li $s0, 100                # Set HP to 100 if over-healed
    j boss_turn

boss_turn:
    # Generate random damage for the boss (between 10 and 30)
    addi $t7, $t7, 3           # Randomizer counter (simplified)
    mfhi $t7                    # Get high bits of $hi (based on timer)
    andi $t7, $t7, 1           # Get random bit (0 or 1)
    mul $t7, $t7, 20           # Scale it (10 or 30)
    add $t7, $t7, 10           # Random damage between 10 and 30

    sub $s0, $s0, $t7          # Apply damage to player's HP

    li $v0, 4
    la $a0, boss_text
    syscall

    # Check win/loss
    blez $s0, lose
    blez $s1, win
    j game_loop

win:
    li $v0, 4
    la $a0, win_text
    syscall
    j exit

lose:
    li $v0, 4
    la $a0, lose_text
    syscall
    j exit

exit:
    li $v0, 10
    syscall
