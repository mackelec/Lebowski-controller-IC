.include "p30F4011.inc"
.include "defines.inc"

.text
.global menu_misc
menu_misc:
    call clr_scr_232
;------------------------------------------------------
;a) autocomplete
;------------------------------------------------------
    mov #tblpage(misc_mes_a), w0
    mov #tbloffset(misc_mes_a), w1
    call tx_str_232

    bra mm_msg_b

mm_opt_a:
    mov #100, w0
    mov w0, motor_standstill_voltage

    bset flags_rom, #pulse_low_side
                                                        ;dr0_xx_msec = 30e6 / (pulserate*main_loop_count) = (30e6/4)/main_loop_count * (1/pulserate) * 4
                                                        ;calculate (30e6/4) / main_loop_count
    mov #114, w1                                            
    mov #28896, w0
    mov main_loop_count, w2
    repeat #17
    div.ud w0, w2                                       ;answer in w0
    mov #20, w2                                         ;w2 = pulserate
    repeat #17
    div.u w0, w2                                        ;answer in w0
    sl w0, #2, w0                                       ;times 4	
    mov w0, dr0_XX_msec

    mov #600, w0
    mov w0, dr0_pulse_duration
    
    mov #16, w0
    mov w0, phi_int_wiggle
    mov #3600, w0
    mov w0, ampli_wiggle
														;1000, or 2000 in hall sensored
    mov #1000, w0
	btsc flags_rom, #hall_mode
	mov #2000, w0
    mov w0, cycles_2to3
	
	bclr menus_completed, #mc_misc

    bra menu_misc

;------------------------------------------------------
;b) motor standstill voltage threshold:
;------------------------------------------------------
mm_msg_b:
    mov #tblpage(misc_mes_b), w0
    mov #tbloffset(misc_mes_b), w1
    call tx_str_232
                                                        ;motor standstill voltage
    mov motor_standstill_voltage, w0
    mov #320, w1                                        ;* 5/1024 * 65536
    mul.uu w0, w1, w0
    push w0
    mov w1,w0
    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232
    pop w0
    mov #str_buf, w1
    call word_to_01_str
    clr.b str_buf+3
    mov #str_buf, w0
    call tx_ram_str_232

    mov #tblpage(misc_mes_b1), w0
    mov #tbloffset(misc_mes_b1), w1
    call tx_str_232

    bra mm_msg_c

mm_opt_b:
    mov #10, w0
    call get_signed_decimal_number
                                                        ;must be below 2 -> all bits except LSB in w0 must be 0
    lsr w0, w0
    bra nz, menu_misc
    rrc w1, w0
                                                        ;already divided by 2,  -> divide by 160 (or mult by 409)
    mov #409, w1
    mul.uu w0, w1, w0

    mov w1, motor_standstill_voltage

    bra menu_misc

;------------------------------------------------------
;c) low side pulsing in drive 0:
;------------------------------------------------------
mm_msg_c:
    mov #tblpage(misc_mes_c), w0
    mov #tbloffset(misc_mes_c), w1
    call tx_str_232

    mov #tblpage(misc_mes_en), w0
    mov #tbloffset(misc_mes_en), w1
    btss flags_rom, #pulse_low_side
    mov #tblpage(misc_mes_dis), w0
    btss flags_rom, #pulse_low_side
    mov #tbloffset(misc_mes_dis), w1
    call tx_str_232

    bra mm_msg_d

mm_opt_c:
    btg flags_rom, #pulse_low_side

    bra menu_misc

;------------------------------------------------------
;d) low side pulsing rate:
;------------------------------------------------------
mm_msg_d:
    mov #tblpage(misc_mes_d), w0
    mov #tbloffset(misc_mes_d), w1
    call tx_str_232
                                                        ;pulserate = 30e6 / (dr0_XX_msec*main_loop_count) = (30e6/4)/main_loop_count * (4/xx)
                                                        ;calculate (30e6/4) / main_loop_count
    mov #114, w1                                            
    mov #28896, w0
    mov main_loop_count, w2
    repeat #17
    div.ud w0, w2                                       ;answer in w0

    mov dr0_XX_msec, w2
    lsr w2, #2, w2
                                                        ;w2 = dr0_XX_msec/4
    repeat #17
    div.u w0, w2                                        ;answer in w0

    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232

    mov #tblpage(misc_mes_d1), w0
    mov #tbloffset(misc_mes_d1), w1
    call tx_str_232

    bra mm_msg_e

mm_opt_d:
    mov #2, w0
    call get_number

    push w0
                                                        ;dr0_xx_msec = 30e6 / (pulserate*main_loop_count) = (30e6/4)/main_loop_count * (1/pulserate) * 4
                                                        ;calculate (30e6/4) / main_loop_count
    mov #114, w1                                            
    mov #28896, w0
    mov main_loop_count, w2
    repeat #17
    div.ud w0, w2                                       ;answer in w0

    pop w2                                              ;w2 = pulserate

    repeat #17
    div.u w0, w2                                        ;answer in w0

    sl w0, #2, w0                                       ;times 4
		
    mov w0, dr0_XX_msec

    bra menu_misc

;------------------------------------------------------
;e) low side pulsing width:
;------------------------------------------------------
mm_msg_e:
    mov #tblpage(misc_mes_e), w0
    mov #tbloffset(misc_mes_e), w1
    call tx_str_232
                                                        ;pulseduration [usec] = dr0_pulse_duration / 30 (as each count = 33 nsec)
    mov dr0_pulse_duration, w0
    mov #30, w2
    repeat #17
    div.u w0, w2
    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232

    mov #tblpage(misc_mes_e1), w0
    mov #tbloffset(misc_mes_e1), w1
    call tx_str_232

    bra mm_msg_f

mm_opt_e:
                                                        ;calculate half-period drive 0 pulse count
    mov #2, w0
    call get_number
                                                        ;times 30 (30 * 33nsec = 1 usec)
	mul.uu w0, #30, w0
                                                        ;must fit in lower 14 bits
	mov #0x3FFF, w1
	and w0, w1, w0

    mov w0, dr0_pulse_duration

    bra menu_misc
    
;------------------------------------------------------
;f) wiggle range:
;------------------------------------------------------
mm_msg_f:
    mov #tblpage(misc_mes_f), w0
    mov #tbloffset(misc_mes_f), w1
    call tx_str_232
                                                        ;range[deg] is ampli_wiggle * 360
	mov #360, w0
	mul ampli_wiggle
	mov w3, w0
	
    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232

    mov #tblpage(misc_mes_f1), w0
    mov #tbloffset(misc_mes_f1), w1
    call tx_str_232
    
    bra mm_msg_g

mm_opt_f:

    mov #3, w0
    call get_number
                                                        ;ampli_wiggle = 182*w0
	mov #182, w1
	mul.uu w0, w1, w0
	
	mov w0, ampli_wiggle

    bra menu_misc
    	
;------------------------------------------------------
;g) wiggle rate:
;------------------------------------------------------
mm_msg_g:
    mov #tblpage(misc_mes_g), w0
    mov #tbloffset(misc_mes_g), w1
    call tx_str_232
                                                        ;rate[Hz] = 458 * phi_int_wiggle / mlc
	mov #458, w0
	mul phi_int_wiggle
	
	mov main_loop_count, w4
	repeat #17
	div.ud w2, w4

    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232
	
    mov #tblpage(misc_mes_g1), w0
    mov #tbloffset(misc_mes_g1), w1
    call tx_str_232
    
    bra mm_msg_h

mm_opt_g:
    mov #3, w0
    call get_number
                                                        ;phi_int_wiggle = rate[Hz] * mlc / 458
	mul main_loop_count
	mov #458, w4
	repeat #17
	div.ud w2, w4

	mov w0, phi_int_wiggle

    bra menu_misc
    
;------------------------------------------------------
;h) minimum # of cycles going from drive 2 to 3
;------------------------------------------------------
mm_msg_h:
    mov #tblpage(misc_mes_h), w0
    mov #tbloffset(misc_mes_h), w1
    call tx_str_232
 
    mov cycles_2to3, w0                                                     
    mov #str_buf, w1
    call word_to_udec_str
    mov #str_buf, w0
    call tx_ram_str_232
    
    bra mm_msg_z

mm_opt_h:

    mov #5, w0
    call get_number

	mov w0, cycles_2to3

    bra menu_misc
;------------------------------------------------------
;z) return to main menu
;------------------------------------------------------
mm_msg_z:
    mov #tblpage(misc_mes_z), w0
    mov #tbloffset(misc_mes_z), w1
    call tx_str_232

    bra mm_msg_choise
mm_opt_z:
    return

;------------------------------------------------------
mm_msg_choise:

    call get_choise

    mov #'a', w1
    cp w0, w1
    bra z, mm_opt_a
    mov #'b', w1
    cp w0, w1
    bra z, mm_opt_b
    mov #'c', w1
    cp w0, w1
    bra z, mm_opt_c
    mov #'d', w1
    cp w0, w1
    bra z, mm_opt_d
    mov #'e', w1
    cp w0, w1
    bra z, mm_opt_e
    mov #'f', w1
    cp w0, w1
    bra z, mm_opt_f
    mov #'g', w1
    cp w0, w1
    bra z, mm_opt_g
    mov #'h', w1
    cp w0, w1
    bra z, mm_opt_h
	mov #'z', w1
    cp w0, w1
    bra z, mm_opt_z

    bra menu_misc

;**********************************************************

misc_mes_a:
    .pascii "\na) autocomplete\n\0"
misc_mes_b:
    .pascii "\nb) motor standstill voltage threshold: \0"
misc_mes_b1:
    .pascii " V\0"
misc_mes_c:
    .pascii "\nc) low side pulsing in drive 0: \0"
misc_mes_d:
    .pascii "\nd) low side pulsing rate: \0"
misc_mes_d1:
    .pascii " Hz\0"
misc_mes_e:
    .pascii "\ne) low side pulsing width: \0"
misc_mes_e1:
    .pascii " usec\0"
misc_mes_f:
    .pascii "\nf) wiggle range: \0"
misc_mes_f1:
    .pascii " deg\0"
misc_mes_g:
    .pascii "\ng) wiggle rate: \0"
misc_mes_g1:
    .pascii " Hz\0"
misc_mes_h:
    .pascii "\nh) minimum # of cycles going from drive 2 to 3: \0"
misc_mes_z:
    .pascii "\n\nz) return to main menu"
    .pascii "\n\n\0"
misc_mes_en:
    .pascii "enabled\0"
misc_mes_dis:
    .pascii "disabled\0"


.end

