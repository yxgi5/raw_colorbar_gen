module  top #(
    parameter  word_width = 'd10,
    parameter  reserved   = 'd0
)
(
	inout  clk_in,
    output [word_width-1:0] pixdata,
    output fv,
    output lv,
    output pixclk,
	output test
);


reg reset_n;
wire clk24M;

/*
OSCH #(
    .NOM_FREQ("24.18")
)u_OSCH
(
    .STDBY(0),
    .OSC(clk24M)
);
*/

always @ (posedge clk24M)
begin
	if (!reset_n ) reset_n <= 1;
end

wire w_pixclk;
//pll_sensor_clk u_pll_sensor_clk(.CLKI(clk24M), .CLKOP(w_pixclk), .CLKOS(pixclk));
pll_sensor_clk u_pll_sensor_clk(.CLKI(clk_in), .CLKOP(w_pixclk), .CLKOS(pixclk));

//pll_sensor_clk u_pll_sensor_clk(.CLKI(clk24M), .CLKOP(w_pixclk));
//assign w_pixclk = pixclk;

wire w_fv;
wire w_lv;
wire [word_width-1:0] w_pixdata;


assign fv = w_fv;
assign lv = w_lv;
assign pixdata = w_pixdata;

raw_colorbar_gen #(
	.h_active  ('d1280 ),
	.h_total   ('d1650 ),
	.v_active  ('d720 ),
	.v_total   ('d750 ),
	.H_FRONT_PORCH ('d110),
	.H_SYNCH       ('d40),
	.H_BACK_PORCH  ('d220),
	.V_FRONT_PORCH ('d5),
	.V_SYNCH       ('d5),
	.bayer_pattern ('d2)
)u_raw_colorbar_gen
(
	.rstn       (reset_n  ) , 
	.clk        (w_pixclk) ,
	.fv         (w_fv) ,
	.lv         (w_lv) ,
	.data       (w_pixdata),
	.vsync      (),
	.hsync      ()
);

endmodule
