# =====================================================
# RPG Turn-Based Battle Simulator in MIPS Assembly
# =====================================================
# This program simulates a turn-based RPG battle between
# the player and a boss enemy. The player has 100 HP and
# the boss has 150 HP. Each turn, the player can choose
# one of three actions:
#   1. Slash - Deal 15 damage to the boss (always hits)
#   2. Fireball - Deal 25 damage to the boss (50% miss chance)
#   3. Heal - Restore 20 HP (maximum 100 HP)
#
# After the player's turn, the boss attacks and deals
# random damage between 10-30 HP to the player.
#
# The game continues until either the player or the boss
# has 0 or less HP. The player wins if the boss's HP drops
# to 0 or below, and loses if their own HP drops to 0 or below.
# =====================================================

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
    # Initialize player and boss HP
    li $s0, 100        # player HP - stored in $s0
    li $s1, 150        # boss HP - stored in $s1
    
    # Initialize random seed for proper randomization
    # Syscall 41 sets the random seed
    # Using seed 0 makes it use the system time as seed
    li $v0, 41
    li $a0, 0          # Seed 0 = time-based seed
    syscall

game_loop:
    # Show current HP status for player and boss
    # Display player HP
    li $v0, 4
    la $a0, hp_status
    syscall
    li $v0, 1
    move $a0, $s0
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # Display boss HP
    li $v0, 4
    la $a0, boss_status
    syscall
    li $v0, 1
    move $a0, $s1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # Display action menu and get player choice
    li $v0, 4
    la $a0, prompt
    syscall

    # Read player choice (1-3)
    li $v0, 5
    syscall
    move $t0, $v0      # user input stored in $t0

    # Branch to the appropriate action based on player choice
    # Option 1: Slash
    li $t1, 1
    beq $t0, $t1, slash
    # Option 2: Fireball
    li $t1, 2
    beq $t0, $t1, fireball
    # Option 3: Heal
    li $t1, 3
    beq $t0, $t1, heal

    j game_loop        # invalid input, return to menu

# ======================================
# PLAYER ACTIONS
# ======================================

slash:
    # Slash attack: Always hits for 15 damage
    li $v0, 4
    la $a0, slash_text
    syscall
    li $t2, 15         # Slash damage = 15
    sub $s1, $s1, $t2  # Subtract damage from boss HP
    j boss_turn

fireball:
    # Fireball attack: 25 damage but 50% chance to miss
    li $v0, 4
    la $a0, fire_text
    syscall

    # Generate random number 0 or 1 for hit/miss (syscall 42)
    # Syscall 42 generates a random integer from 0 to ($a1-1)
    li $v0, 42
    li $a0, 1          # Random generator ID
    li $a1, 2          # Upper bound (exclusive), so 0-1
    syscall            # Result in $a0
    
    bnez $a0, fire_miss    # If $a0 is 1 (50% chance), fireball misses

    # Fireball hits
    li $t2, 25             # Fireball damage = 25
    sub $s1, $s1, $t2      # Apply damage to the boss
    j boss_turn

fire_miss:
    # Fireball missed (no damage dealt)
    li $v0, 4
    la $a0, miss_text
    syscall
    j boss_turn

heal:
    # Heal: Restore 20 HP (up to maximum of 100)
    li $v0, 4
    la $a0, heal_text
    syscall

    # Check if player's HP is already full (100)
    li $t2, 100
    beq $s0, $t2, boss_turn   # If HP is already 100, skip healing

    li $t2, 20                # Heal value = 20
    add $s0, $s0, $t2         # Add healing to player's HP

    # Cap player's HP at 100 if healed above maximum
    li $t3, 100
    bgt $s0, $t3, cap_hp

    j boss_turn

cap_hp:
    # Set HP to maximum (100) if over-healed
    li $s0, 100
    j boss_turn

# ======================================
# BOSS TURN
# ======================================

boss_turn:
    # Generate random boss damage between 10 and 30
    # Syscall 42 generates a random integer in the range [0, $a1-1]
    li $v0, 42
    li $a0, 1          # Random generator ID
    li $a1, 21         # Upper bound (exclusive), so 0-20
    syscall            # Result in $a0
    
    addi $a0, $a0, 10  # Add 10 to get range 10-30
    sub $s0, $s0, $a0  # Apply damage to player's HP

    # Announce the boss attack
    li $v0, 4
    la $a0, boss_text
    syscall

    # Check win/loss conditions
    blez $s0, lose     # Player HP <= 0 -> lose
    blez $s1, win      # Boss HP <= 0 -> win
    j game_loop        # Neither won nor lost, continue game

# ======================================
# GAME OUTCOMES
# ======================================

win:
    # Player wins (boss HP <= 0)
    li $v0, 4
    la $a0, win_text
    syscall
    j exit

lose:
    # Player loses (player HP <= 0)
    li $v0, 4
    la $a0, lose_text
    syscall
    j exit

exit:
    # Terminate the program
    li $v0, 10
    syscall
