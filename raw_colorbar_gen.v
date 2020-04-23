module raw_colorbar_gen #(
	parameter word_width    = 'd10       ,
    parameter h_active      = 'd1920     ,
    parameter h_total       = 'd2200     ,
    parameter v_active      = 'd1080     ,
    parameter v_total       = 'd1125     ,
    parameter H_FRONT_PORCH =   'd88     ,
    parameter H_SYNCH       =   'd44     ,
    parameter H_BACK_PORCH  =  'd148     ,
    parameter V_FRONT_PORCH =    'd4     ,
    parameter V_SYNCH       =    'd5     ,
	parameter bayer_pattern =     3      ,      // 0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR
    parameter mode          =     0             //
)
( 
    input                         rstn       , 
    input                         clk        , 
    output         reg            fv         , 
    output         reg            lv         , 
	output  [word_width-1:0]     data       ,
    output         reg            vsync      ,
    output         reg            hsync      
);

//`define WORD_WIDTH word_width

reg [11:0] pixcnt; 
reg [11:0] linecnt;
reg [10:0] fv_cnt;
reg [11:0] color_cntr;	
reg        q_fv;
reg [7:0]  rstn_cnt;
reg [11:0] ative_line_cnt;

// count rstn hi every posedge clk, until rstn == 128
// it means rstn keeping hi for 128 clks
always @(posedge clk or negedge rstn) 
if (!rstn) 
	 rstn_cnt <= 0;
else
	 rstn_cnt <= rstn_cnt[7] ? rstn_cnt : rstn_cnt+1;
		 

always @(posedge clk or negedge rstn_cnt[7]) 
begin 
    // when rstn keeping hi less than 128 clks
	// reset these values
    if (!rstn_cnt[7]) 
    begin 
		fv_cnt    <= 0;  
		pixcnt    <= 12'd0; 

		linecnt   <= 12'd0;

		lv        <= 1'b0;  
		fv        <= 1'b0;  
		q_fv      <= 0;                                    

		hsync     <= 0;
		vsync     <= 0;         
    end
	// when rstn keeping hi more than 128 clks
    else 
	begin 
		// frame valid counter, 
		// if fv_cnt less than 'd2047, add 1 when fv=0, q_fv=1
		// else fv_cnt keeping 'd2047
		// 
		// equal to 
		// if ( fv=0 and q_fv=1), then 
		//   if (fv_cnt < 'd2047) then fv_cnt <= fv_cnt+1
		//   else fv_cnt <= fv_cnt
		//
		// tip:
		// if fv=1,q_fv=0, then ~fv&q_fv=0
		// if fv=1,q_fv=1, then ~fv&q_fv=0
		// if fv=0,q_fv=0, then ~fv&q_fv=0
		// if fv=0,q_fv=1, then ~fv&q_fv=1
		fv_cnt    <= (fv_cnt==11'h7FF)  ? 11'h7FF  : fv_cnt+ (~fv&q_fv);
		
		// pixel counter in one line, 
		// if pixcnt less than h_total, then pixcnt add 1
		// else pixcnt <= 0
		pixcnt    <= (pixcnt<h_total-1) ? pixcnt+1 : 0;  
		
		// line counter in one frame,	
		// if pixcnt == h_total-1, then
		//   if linecnt< v_total-1, then linecnt <= linecnt+1
		//   else if linecnt==v_total-1, then linecnt <= 0
		// else pixcnt < h_total-1, then linecnt <= linecnt
		linecnt   <= (linecnt==v_total-1 && pixcnt ==h_total-1)  ? 0         :  
				   (linecnt< v_total-1 && pixcnt ==h_total-1)  ? linecnt+1 : linecnt; 
		
        // line valid,
		// linecnt between 1 and v_active
		// pixcnt between 1 and h_active
		lv        <= (pixcnt>12'd0)   & (pixcnt<=h_active) & (linecnt> 0 & linecnt<=v_active); 
		
		// frame valid, 
		// linecnt between 0 and v_active+1
		fv        <= (linecnt>=12'd0) & (linecnt<=v_active+1);
		
		// prev fv, frame valid value in last clk
		q_fv      <= fv; 

		// 
		hsync     <= (pixcnt>h_active+H_FRONT_PORCH)   & (pixcnt<=h_active+H_FRONT_PORCH+H_SYNCH); 
		
		// 
		vsync     <= (linecnt>=v_active+V_FRONT_PORCH) & (linecnt<v_active+V_FRONT_PORCH+V_SYNCH);       	   
    end 
end 		 


// count pixel when line valid
always @(posedge clk or negedge rstn_cnt[7])
if(!rstn_cnt[7])
	 color_cntr <= 0;
else
	 color_cntr <= lv ? color_cntr+1 : 0;

// count lines when frame valid
always @(posedge clk or negedge rstn_cnt[7])
if(!rstn_cnt[7])
	 ative_line_cnt <= 0;
else
	 ative_line_cnt <= fv ? (pixcnt ==h_total-1)?ative_line_cnt+1: ative_line_cnt : 0;

reg [23:0] pix_rgb;
reg [word_width-1:0]     raw_data;
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		pix_rgb  <= 24'b0;
	end
	else
	begin
		if((color_cntr%480)<160)
		begin
			pix_rgb <= {8'hFF, 8'h00, 8'h00} ;
		end
		else if((color_cntr%480)<320)
		begin
			pix_rgb <= {8'h00, 8'hFF, 8'h00} ;
		end
		else
		begin
			pix_rgb <= {8'h00, 8'h00, 8'hFF} ;
		end
	end
end
/*
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt%2==0)
		begin
			if(pixcnt%2==0)
			begin
				//raw_data <= (pix_rgb[7:0] == 8'h00)? 10'b0:(pix_rgb[7:0] == 8'hff)? 10'b11_1111_1111:10'b0;
				//raw_data <= (pix_rgb[7:0] == 8'h00)? {(word_width) {1'b0}} : (pix_rgb[7:0] == 8'hff)? {(word_width) {1'b1}} : {(word_width) {1'b0}} ;
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b0}} : {(word_width) {1'b1}};
		    end
			else
		    begin
				//raw_data <= (pix_rgb[15:8] == 8'h00)? 10'b0:(pix_rgb[15:8] == 8'hff)? 10'b11_1111_1111:10'b0;
				//raw_data <= (pix_rgb[15:8] == 8'h00)? {(word_width) {1'b0}} : (pix_rgb[15:8] == 8'hff)? {(word_width) {1'b1}} : {(word_width) {1'b0}} ;
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b1}} : {(word_width) {1'b0}};
			end
		end
		else
		begin
            if(pixcnt%2==0)
			begin
				//raw_data <= (pix_rgb[15:8] == 8'h00)? 10'b0:(pix_rgb[15:8] == 8'hff)? 10'b11_1111_1111:10'b0;
				//raw_data <= (pix_rgb[15:8] == 8'h00)? {(word_width) {1'b0}} : (pix_rgb[15:8] == 8'hff)? {(word_width) {1'b1}} : {(word_width) {1'b0}} ;
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b1}} : {(word_width) {1'b0}};
		    end
			else
		    begin
				//raw_data <= (pix_rgb[23:16] == 8'h00)? 10'b0:(pix_rgb[23:16] == 8'hff)? 10'b11_1111_1111:10'b0;
				//raw_data <= (pix_rgb[23:16] == 8'h00)? {(word_width) {1'b0}} : (pix_rgb[23:16] == 8'hff)? {(word_width) {1'b1}} : {(word_width) {1'b0}} ;
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b1}} : ((color_cntr%480)<320) ? {(word_width) {1'b0}} : {(word_width) {1'b0}};
			end
		end
	end
end
*/

/*
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b1}};
				//raw_data <= 10'b00_1111_1111;
		    end
			else
		    begin
				//raw_data <= {(word_width) {1'b0}};
				raw_data <= 10'b00_0000_0000;
			end
		end
		else
		begin
            if(pixcnt[0]==1'b0)
			begin
				//raw_data <= {(word_width) {1'b0}};
				raw_data <= 10'b00_0000_0000;
		    end
			else
		    begin
				//raw_data <= {(word_width) {1'b0}};
				raw_data <= 10'b00_0000_0000;
			end
		end
	end
end
*/

/*
// following 4 paterns works good when pclk adjust 180 degree
// green
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b0}}; // R
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b1}}; // Gr
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b0}}; // R
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b1}}; // Gr
			end
		end
		else
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b1}}; // Gb
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b1}}; // Gb
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
		end
	end
end


// red
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b1}}; // R
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b1}}; // R
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
		end
		else
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b0}}; // Gb
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gb
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
		end
	end
end


// blue
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b0}}; // R
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b0}}; // R
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
		end
		else
		begin
            if((pixcnt%4)==0)
			begin
				raw_data <= {(word_width) {1'b0}}; // Gb
		    end
			else if((pixcnt%4)==1)
		    begin
				raw_data <= {(word_width) {1'b1}}; // B
			end
			else if((pixcnt%4)==2)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gb
			end
			else if((pixcnt%4)==3)
		    begin
				raw_data <= {(word_width) {1'b1}}; // B
			end
		end
	end
end
*/

/*
// following 4 patens works good when pclk shift 225 degree
// Red
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b1}}; // R
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
		end
		else if(linecnt[0]==1'b1)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b0}}; // Gb
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
		end
	end
end

// green
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b0}}; // R
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b1}}; // Gr
			end
		end
		else if(linecnt[0]==1'b1)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b1}}; // Gb
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // B
			end
		end
	end
end


// blue
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b0}}; // R
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b0}}; // Gr
			end
		end
		else if(linecnt[0]==1'b1)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= {(word_width) {1'b0}}; // Gb
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= {(word_width) {1'b1}}; // B
			end
		end
	end
end
*/

// pclk shift 225 degree to hi3516dv300 as BGGR bayer source
// R | G | B | R | G | B ...
always @(posedge clk or negedge rstn_cnt[7])
begin
	if(!rstn_cnt[7])
	begin
		raw_data  <= 0;
	end
	else
	begin
		if(linecnt[0]==1'b0)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b1}} : ((color_cntr%480)<320) ? {(word_width) {1'b0}} : {(word_width) {1'b0}};
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b1}} : {(word_width) {1'b0}};
			end
		end
		else if(linecnt[0]==1'b1)
		begin
            if(pixcnt[0]==1'b0)
			begin
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b1}} : {(word_width) {1'b0}};
		    end
			else if(pixcnt[0]==1'b1)
		    begin
				raw_data <= ((color_cntr%480)<160)? {(word_width) {1'b0}} : ((color_cntr%480)<320) ? {(word_width) {1'b0}} : {(word_width) {1'b1}};
			end
		end
	end
end

assign data = raw_data;

endmodule