	.global MAIN
	
	.data
i      .word   0x3000    ;initial value of current
iref   .word   0x4daa    ;reference value of current
Kp     .word   0x1999    ;Kp = 0.199
Ki     .word   0x1999    ;Ki = 0.199                (Kp and Ki set to same value since Kp/Ki = 1 and the values of R and L taken are same)
d1     .word   0x0ccc    ;d1 = (T/L)
d2     .word   0x7ffe    ;d2 = 1/(1 + (R*T)/L)


	.text

set_val:
	movw	@AR6, #0x07ff	 ;AR6 as counter for iteration to calculate current of RL circuit regulated by PI controller
	mov	AR3,#0x0000	  ;initial value of summation of errrors = 0
	movl	XAR2,#0x9000     ;XAR2 as pointer to starting address of LS2 RAM for storing the values of current calculated at each iteration

iter:
	movw	DP, #i           ;direct addressing mode used
      	movw	AH,@i            ;input moved to AH register
      	movw    AR5,AH           ;AR5 will keep track of value of i 
      	mov	AL,@iref	  ;reference value of current i
      	mov	AR0,AL	          ;AR0 always keep reference current value 
      	
      	
      	
	;;Implementation of PI controller
	;;V(n) = (Kp*e(n) + Ki*summation(e(n)))
	;;where e(n) = Iref - I(n) = AR0 - AR5
	mov	AR1,AR0           ;moving current reference value to AR1 for calculation purpose
	mov	AL,AR1            ;moving iref to AL for subtraction
	sub	AL,AR5            ;AR5 = e(n) = iref - i(n)
	mov	AR1,AL
	mov	AL,AR3            ;AR3 = e(n) + e(n-1) + e(n-2) + ....
	add	AL,AR1
	mov	AR3,AL
	movw	T,AR3
	mpy	P,T,@Ki
	movl	ACC, P>>PM
	mov	AR4,AH            ;AR4 = Ki*(e(n) + e(n-1) + e(n-2) + ....)
	movw	T,AR1
	mpy	P,T,@Kp           ;P = Kp*e(n)
	movl	ACC,P>>PM
	add	AR4,AH            ;V(n) = Kp*e(n) + Ki*(e(n) + e(n-1) + e(n-2) + ....)
	

	;;Finding the value of current i using Euler Implicit Method	
	;;i(n+1) = (i(n) + V(n)*T/L)/(1 + R*T/L)
	;;where V(n) is obtained as output from PI controller
	movw	T,AR4
	mpy	P,T,@d1           ;P = V(n)*T/L
	movl	ACC,P>>PM
	add	AH,AR5            ;AH = i(n) + V(n)*T/L
	movw	T,AH
	mpy	P,T,@d2           
	movl	ACC,P>>PM
	mov	AR5,AH	           ;i(n+1) = (i(n) + V(n)*T/L)/(1 + (R*T)/L)
	movw	@i,AR5             ; now i contains latest value
	
	movw	*XAR2++,AH         ; move to the next location in LS2 RAM pointed by XAR2 register
	
	banz	iter,AR6--         ;loop keeps running, evaluating current, until content of AR6 becomes 0
	
	lretr
	
MAIN:
      	spm	1
	lcr	set_val
	
spin:	lb	spin
	.end
	
	


