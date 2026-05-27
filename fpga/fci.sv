
typedef struct{
	
	bit [31:0]addr;
	bit [7:0]dato;
	bit oe; 
	bit we;
	bit act;
	bit clk;
	bit io_ck;
	bit wr_ck;
	
}FciBus;

//********************************

module fci_io(

	input  clk,
	input  [7:0]dati,
	input  mosi, ss, spi_clk,
	
	output miso,
	output FciBus fci	
);
	
	
	assign fci.addr[31:0]	= aout[31:0];
	assign fci.dato[7:0]		= dout[7:0];
	assign fci.oe				= fci_oe;
	assign fci.we				= fci_we;
	assign fci.act				= fci_act;
	assign fci.clk				= spi_clk;
	assign fci.io_ck			= fci_ck;
	assign fci.wr_ck			= fci_ck & fci_we;

	
	reg[7:0]dout;
	reg[31:0]aout;
	wire fci_we, fci_oe, fci_ck;
	reg fci_act;
	
	
	parameter CMD_MEM_WR	= 8'hA0;
	parameter CMD_MEM_RD	= 8'hA1;
	
	assign miso 			= !ss ? sout[7] : 1'bz;
	assign fci_oe 			= cmd[7:0] == CMD_MEM_RD & exec;
	assign fci_we 			= cmd[7:0] == CMD_MEM_WR & exec;
	assign fci_ck 			= fci_act_ff[1:0] == 2'b01;
	
	reg [7:0]sin;
	reg [7:0]sout;
	reg [2:0]bit_ctr;
	reg [7:0]cmd;
	reg [3:0]byte_ctr;
	reg [7:0]rd_buff;
	reg wr_ok;
	reg exec;
	reg [1:0]fci_act_ff;
	
	
	always @(posedge clk)
	begin
		fci_act_ff[1:0] <= {fci_act_ff[0], fci_act};
	end
	
	
	always @(posedge spi_clk)
	begin
		sin[7:0] <= {sin[6:0], mosi};
	end
	
	
	always @(negedge spi_clk)
	if(ss)
	begin
		cmd[7:0] 		<= 8'h00;
		sout[7:0] 		<= 8'hff;
		bit_ctr[2:0] 	<= 3'd0;
		byte_ctr[3:0] 	<= 4'd0;
		fci_act 			<= 0;
		wr_ok 			<= 0;
		exec 				<= 0;
	end
		else
	begin
		
		
		bit_ctr <= bit_ctr + 1;
				
		
		if(bit_ctr == 7 & !exec)
		begin
			if(byte_ctr[3:0] == 4'd0)cmd[7:0] 		<= sin[7:0];
			if(byte_ctr[3:0] == 4'd1)aout[7:0] 		<= sin[7:0];
			if(byte_ctr[3:0] == 4'd2)aout[15:8] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd3)aout[23:16] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)aout[31:24] 	<= sin[7:0];
			if(byte_ctr[3:0] == 4'd4)exec <= 1;
			byte_ctr <= byte_ctr + 1;
		end
		
		
		
		if(cmd[7:0] == CMD_MEM_WR & exec)
		begin
			if(bit_ctr == 7)dout[7:0] 			<= sin[7:0];
			if(bit_ctr == 7)wr_ok 				<= 1;
			if(bit_ctr == 0 & wr_ok)fci_act 	<= 1;
			if(bit_ctr == 5 & wr_ok)fci_act 	<= 0;
			if(bit_ctr == 6 & wr_ok)aout 		<= aout + 1;
		end

		
		if(cmd[7:0] == CMD_MEM_RD & exec)
		begin
			if(bit_ctr == 1)fci_act 		<= 1;
			if(bit_ctr == 5)rd_buff[7:0] 	<= dati[7:0];
			if(bit_ctr == 5)aout 			<= aout + 1;
			if(bit_ctr == 5)fci_act 		<= 0;//should not release on last cycle. otherwise spi clocked thing may not work properly
			if(bit_ctr == 7)sout[7:0] 		<= rd_buff[7:0];
			
			if(bit_ctr != 7)sout[7:0] 		<= {sout[6:0], 1'b1};
		end
		
	end
	
	
endmodule
