.data
nl: .asciz "\n"
.text
#Square root done with Binary search.
#Note: DO NOT USE A N Y OF THE POINTERS AS GENERAL PURPOSE REGISTERS
main:
lia0,0#argumentative register
li
ecalla7,5#Calls in method to read int,
li sp,0
li gp,256
add sp,sp,zero
slli gp,gp,14#start guess at 0
#set step to 256
#build the guess
#set to 256 w/ 14 fractional bits
mul tp,sp,sp
mulhu t1,sp,sp
srli tp,tp,14
slli t1,t1,18
or tp,tp,t1
beq tp, a0, done
bltu tp,a0,L1
sub sp,sp,gp
j L2
add sp,sp,gp#square guess; grab low bits
#square guess; grab hi hits
#shift to the right by 14 bits
for:
L1:
L2:
srli gp,gp,1
beq gp,zero,done
j for
#OR the 2 registers and store it in 'tp'
#if exact, then exit
# shift gp right by one
#break if gp == 0
done:
add
li
ecall
li
ecall
a0,sp,zero
a7, 1#use argument to print
#syscall to print int
a7,10#Exits program
