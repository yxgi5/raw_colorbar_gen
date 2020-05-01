[ActiveSupport MAP]
Device = LFE5UM-85F;
Package = CABGA756;
Performance = 8;
LUTS_avail = 83640;
LUTS_used = 144;
FF_avail = 84005;
FF_used = 36;
INPUT_LVCMOS33 = 1;
OUTPUT_LVCMOS18 = 14;
IO_avail = 365;
IO_used = 15;
EBR_avail = 208;
EBR_used = 0;
;
; start of DSP statistics
MULT18X18D = 0;
MULT9X9D = 0;
ALU54B = 0;
ALU24B = 0;
PRADD18A = 0;
PRADD9A = 0;
DSP_MULT_avail = 312;
DSP_MULT_used = 0;
DSP_ALU_avail = 156;
DSP_ALU_used = 0;
DSP_PRADD_avail = 312;
DSP_PRADD_used = 0;
; end of DSP statistics
;
; Begin PLL Section
Instance_Name = u_pll_sensor_clk/PLLInst_0;
Type = EHXPLLL;
CLKOP_Post_Divider_A_Input = DIVA;
CLKOS_Post_Divider_B_Input = DIVB;
CLKOS2_Post_Divider_C_Input = DIVC;
CLKOS3_Post_Divider_D_Input = DIVD;
FB_MODE = CLKOP;
CLKI_Divider = 2;
CLKFB_Divider = 3;
CLKOP_Divider = 16;
CLKOS_Divider = 16;
CLKOS2_Divider = 1;
CLKOS3_Divider = 1;
CLKOP_Desired_Phase_Shift(degree) = 0;
CLKOP_Trim_Option_Rising/Falling = FALLING;
CLKOP_Trim_Option_Delay = 0;
CLKOS_Desired_Phase_Shift(degree) = 180;
CLKOS_Trim_Option_Rising/Falling = FALLING;
CLKOS_Trim_Option_Delay = 0;
CLKOS2_Desired_Phase_Shift(degree) = 0;
CLKOS3_Desired_Phase_Shift(degree) = 0;
; End PLL Section
