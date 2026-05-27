

//megadoctor mapper

module doc(
		
	output [15:0]MD_DI,
	input  [15:0]MD_DO,
	input  [23:1]MD_A,
	input  MD_ASn,
	input  MD_CASn,
	input  MD_CEHn,
	input  MD_CELn,
	input  MD_OEn,
	input  MD_WEHn,
	input  MD_WELn,
	input  MD_VCLK,
	input  MD_ECLK,
	input  MD_SRSTFn,
	input  MD_DTAKn,
	output MD_CART,
	output MD_DQ,
	
	
	output [21:0]ROM_A,
	input  [15:0]ROM_D,
	output ROM_OE,
	output ROM_CE,
	
	input  FCI_SSn,
	input  FCI_MOSI,
	input  FCI_SCK,
	output FCI_MISO,
	
	input  CLK
);

	wire clk				= CLK;
	
	wire rst				= rst_ff == 'b001;
	
	reg [2:0]rst_ff;
	always @(posedge clk)
	begin
		rst_ff			<= {rst_ff[1:0], MD_SRSTFn};
	end
//************************************************************************************* fci
	wire [7:0]fci_dati;
	FciBus fci;
	
	fci_io(

		.clk(clk),
		.dati(fci_dati),
		.mosi(FCI_MOSI),
		.ss(FCI_SSn),
		.spi_clk(FCI_SCK),
		
		.miso(FCI_MISO),
		.fci(fci)
	);
	

	assign fci_dati	= fci.addr < 64 ? cpu_reg_8 : ctr_regs[fci.addr[3:0]];
	
//************************************************************************************* md bus
	assign MD_DQ		= cart_ce & cart_oe;
	
	assign MD_DI		= ROM_D;
	assign ROM_A		= MD_A[10:1];//2Kb
	assign ROM_OE		= cart_oe;
	assign ROM_CE		= cart_ce;
	
	wire cart_ce		= !MD_CELn | (!MD_CEHn & MD_CART);
	wire cart_oe		= !MD_OEn;
	wire cart_we		= !MD_WELn;
	
	always @(posedge clk)
	if(fci.wr_ck & fci.addr == 0)
	begin
		MD_CART			<= fci.dato[0];
	end
//************************************************************************************* counters var
	wire [31:0]vclk_ctr;
	clk_ctr clk_vclk(.clk(clk), .rst(rst), .sig(MD_VCLK), .val(vclk_ctr));
	
	wire [31:0]eclk_ctr;
	clk_ctr clk_eclk(.clk(clk), .rst(rst), .sig(MD_ECLK), .val(eclk_ctr));
	
	wire [7:0]oe_ctr;
	sig_ctr sig_oe(.clk(clk), .rst(rst), .sig(MD_OEn), .val(oe_ctr));
	
	wire [7:0]ce_lo_ctr;
	sig_ctr sig_ce_lo(.clk(clk), .rst(rst), .sig(MD_CELn), .val(ce_lo_ctr));
	
	wire [7:0]ce_hi_ctr;
	sig_ctr sig_ce_hi(.clk(clk), .rst(rst), .sig(MD_CEHn), .val(ce_hi_ctr));
	
	wire [7:0]we_lo_ctr;
	sig_ctr sig_we_lo(.clk(clk), .rst(rst), .sig(MD_WELn), .val(we_lo_ctr));
	
	wire [7:0]we_hi_ctr;
	sig_ctr sig_we_hi(.clk(clk), .rst(rst), .sig(MD_WEHn), .val(we_hi_ctr));
	
	wire [7:0]as_ctr;
	sig_ctr sig_as(.clk(clk), .rst(rst), .sig(MD_ASn), .val(as_ctr));
	
	wire [7:0]dt_ctr;
	sig_ctr sig_dt(.clk(clk), .rst(rst), .sig(MD_DTAKn), .val(dt_ctr));
	
	wire [23:0]err_addr;
	addr_ctr(.clk(clk), .rst(rst), .addr(MD_A[7:1] * 2), 	.err(err_addr[7:0]));
	addr_ctr(.clk(clk), .rst(rst), .addr(MD_A[15:8]),  	.err(err_addr[15:8]));
	addr_ctr(.clk(clk), .rst(rst), .addr(MD_A[23:16]), 	.err(err_addr[23:16]));


//************************************************************************************* 
	
	reg [7:0]ctr_regs[16];
	
	always @(posedge clk)
	if(!fci.oe)
	begin
		ctr_regs[0]		<= vclk_ctr[23:16];
		ctr_regs[1]		<= vclk_ctr[15:8];
		ctr_regs[2]		<= vclk_ctr[7:0];
		
		ctr_regs[3]		<= eclk_ctr[23:16];
		ctr_regs[4]		<= eclk_ctr[15:8];
		ctr_regs[5]		<= eclk_ctr[7:0];
		
		ctr_regs[6]		<= oe_ctr;
		ctr_regs[7]		<= ce_lo_ctr;
		ctr_regs[8]		<= ce_hi_ctr;
		ctr_regs[9]		<= we_lo_ctr;
		ctr_regs[10]	<= we_hi_ctr;
		ctr_regs[11]	<= as_ctr;
		ctr_regs[12]	<= dt_ctr;
		ctr_regs[13]	<= err_addr[23:16];
		ctr_regs[14]	<= err_addr[15:8];
		ctr_regs[15]	<= err_addr[7:0];
	end
	
//************************************************************************************* cpu regs	
	reg [15:0]cpu_regs[32];
	reg [3:0]we_lo_ff;
	reg [3:0]we_hi_ff;
	
	
	always @(posedge clk)
	if(rst)
	begin
		we_lo_ff		<= 0;
		we_hi_ff		<= 0;
		cpu_regs 	<= '{default:'0};
	end
		else
	begin
		
		we_lo_ff		<= {we_lo_ff[2:0], MD_WELn};
		we_hi_ff		<= {we_hi_ff[2:0], MD_WEHn};
		
		if(we_lo_ff == 'b1000 & cart_ce)
		begin
			cpu_regs[MD_A[5:1]][7:0]	<= MD_DO[7:0];
		end
		
		if(we_hi_ff == 'b1000 & cart_ce)
		begin
			cpu_regs[MD_A[5:1]][15:8]	<= MD_DO[15:8];
		end
	end
	
	
	wire [7:0]cpu_reg_8	= 
	fci.addr[0] == 0 ? cpu_regs[fci.addr[5:1]][15:8]  : cpu_regs[fci.addr[5:1]][7:0];
	
//*************************************************************************************

endmodule

//********************************

module sig_ctr(

	input  clk,
	input  rst,
	input  sig,
	output [7:0]val
);
	
	
	reg [2:0]sig_ff;
	
	always @(posedge clk)
	if(rst)
	begin
		sig_ff	<= 0;
		val		<= 0;
	end
		else
	begin
		
		sig_ff	<= {sig_ff[1:0], sig};
		
		if(sig_ff == 'b100 & val < 'h80)
		begin
			val	<= val + 1;
		end
		
	end

endmodule

//********************************

module clk_ctr(

	input  clk,
	input  rst,
	input  sig,
	output [31:0]val
);
	
	
	parameter CLK_FREQ	= 50000000;
	
	reg [31:0]clk_ctr;
	reg [31:0]sig_ctr;
	
	always @(posedge clk)
	if(rst)
	begin
		clk_ctr		<= 0;
		sig_ctr		<= 0;
		val			<= 0;
	end
		else
	if(clk_ctr == CLK_FREQ - 1)
	begin
		clk_ctr		<= 0;
		sig_ctr		<= 0;
		val			<= sig_ctr;
	end
		else
	begin
		
		clk_ctr		<= clk_ctr + 1;
		
		if(sig_ff[1:0] == 'b10)
		begin
			sig_ctr	<= sig_ctr + 1;
		end
		
	end
	
	
	reg [2:0]sig_ff;
	always @(posedge clk)
	begin
		sig_ff		<= {sig_ff[1:0], sig};
	end
	

endmodule

//********************************

module addr_ctr(

	input  clk,
	input  rst,
	input  [7:0]addr,
	output [7:0]err
);
	
	parameter MIN_CYCLES	= 8;
	
	assign err[0]	= a0 < MIN_CYCLES;
	assign err[1]	= a1 < MIN_CYCLES;
	assign err[2]	= a2 < MIN_CYCLES;
	assign err[3]	= a3 < MIN_CYCLES;
	assign err[4]	= a4 < MIN_CYCLES;
	assign err[5]	= a5 < MIN_CYCLES;
	assign err[6]	= a6 < MIN_CYCLES;
	assign err[7]	= a7 < MIN_CYCLES;
	
	
	wire [7:0]a0;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[0]), .val(a0));
	
	wire [7:0]a1;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[1]), .val(a1));
	
	wire [7:0]a2;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[2]), .val(a2));
	
	wire [7:0]a3;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[3]), .val(a3));
	
	wire [7:0]a4;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[4]), .val(a4));
	
	wire [7:0]a5;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[5]), .val(a5));
	
	wire [7:0]a6;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[6]), .val(a6));
	
	wire [7:0]a7;
	sig_ctr (.clk(clk), .rst(rst), .sig(addr[7]), .val(a7));

	
endmodule
