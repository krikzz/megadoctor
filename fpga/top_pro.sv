
module top(
	
	inout  [15:0]MD_D,
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
	output MD_CART,
	inout  MD_DTAKn,
	output MD_HRSTFn,
	output [3:0]MD_SMS,
	
	output MD_DDIR,
	output MD_DOEn,
	
	output MKEY_ACT,
	output MKEY_SET,
	
	output [21:0]PSR0_A,
	inout  [15:0]PSR0_D,
	output PSR0_OEn,
	output PSR0_WEn,
	output PSR0_LBn,
	output PSR0_UBn,
	output PSR0_CEn,
	
	output [21:0]PSR1_A,
	inout  [15:0]PSR1_D,
	output PSR1_OEn,
	output PSR1_WEn,
	output PSR1_LBn,
	output PSR1_UBn,
	output PSR1_CEn,
	
	output [17:0]SRM_A,
	inout  [15:0]SRM_D,
	output SRM_OEn,
	output SRM_WEn,
	output SRM_LBn,
	output SRM_UBn,
	output SRM_CEn,
	
	output [17:0]BRM_A,
	inout  [15:0]BRM_D,	
	output BRM_OEn,
	output BRM_WEn,
	output BRM_LBn,
	output BRM_UBn,
	
	inout  [9:0]FCI_IO,
	input  FCI_MOSI,
	input  FCI_SCK,
	output FCI_MISO,
	//input  DCLK,//shorted with FCI_SCK
	
	input  FPG_GPCK,
	inout  [4:0]FPG_GPIO,
	
	input  CLK,
	input  BTN,
	output LED_G,
	output LED_R,
	
	output DAC_MCLK, 
	output DAC_LRCK, 
	output DAC_SCLK, 
	output DAC_SDIN
	
);

//************************************************************************************* unused signals
	assign FCI_IO[2] 		= 1;//mcu fifo interface (unused, should be 1)
	assign FCI_IO[4] 		= 1;//mcu master mode (unused, should be 1)
	
	assign MD_SMS			= 4'bzzzz;
	//assign MD_CART			= 0;
	assign MD_DTAKn		= 1'bz;
	assign MD_HRSTFn		= 1'bz;
	
	assign MKEY_ACT		= 1;
	assign LED_G			= 1'bz;
	assign LED_R			= 1'bz;
	
	assign PSR1_A			= 0;
	assign PSR1_D			= 0;
	assign PSR1_CEn		= 1;
	assign SRM_A			= 0;
	assign SRM_D			= 0;
	assign SRM_CEn			= 1;

	assign BRM_LBn			= 1;
	assign BRM_UBn			= 1;	
//************************************************************************************* reset controller	
	assign FCI_IO[6] 		= BTN     ? 1'b1 : 1'b0;//return to menu
//************************************************************************************* bus controll
	assign MD_DDIR			= MD_DQ ? 1 : 0;
	assign MD_DOEn			= 0;
	assign MD_D				= MD_DQ ? MD_DI : 16'hzzzz;// !MD_DDIR ? 16'hzzzz : !PSR0_CEn ? PSR0_D[15:0] : {BRM_D[7:0], BRM_D[7:0]};
//************************************************************************************* ROM	
	assign PSR0_D[15:0]	= 16'hzzzz;
	assign PSR0_OEn 		= !ROM_OE;
	assign PSR0_WEn		= 1;
	assign PSR0_LBn		= 0;
	assign PSR0_UBn		= 0;
	assign PSR0_CEn		= !ROM_CE;
//************************************************************************************* doctor mapper
	wire [15:0]MD_DI;
	wire MD_DQ;
	wire ROM_OE;
	wire ROM_CE;
	
	doc(
			
		.MD_DI(MD_DI),
		.MD_DO(MD_D),
		.MD_A(MD_A),
		.MD_ASn(MD_ASn),
		.MD_CASn(MD_CASn),
		.MD_CEHn(MD_CEHn),
		.MD_CELn(MD_CELn),
		.MD_OEn(MD_OEn),
		.MD_WEHn(MD_WEHn),
		.MD_WELn(MD_WELn),
		.MD_VCLK(MD_VCLK),
		.MD_ECLK(MD_ECLK),
		.MD_SRSTFn(MD_SRSTFn),
		.MD_DTAKn(MD_DTAKn),
		.MD_CART(MD_CART),
		.MD_DQ(MD_DQ),
		
		
		.ROM_A(PSR0_A),
		.ROM_D(PSR0_D),
		.ROM_OE(ROM_OE),
		.ROM_CE(ROM_CE),
		
		.FCI_SSn(FCI_IO[1]),
		.FCI_MOSI(FCI_MOSI),
		.FCI_SCK(FCI_SCK),
		.FCI_MISO(FCI_MISO),
		
		.CLK(CLK)
	);
	
endmodule
