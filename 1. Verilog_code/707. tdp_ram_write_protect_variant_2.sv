//SystemVerilog
module tdp_ram_write_protect #(
    parameter DW = 20,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] protect_start,
    input [AW-1:0] protect_end,
    // Port1
    input [AW-1:0] addr1,
    input [DW-1:0] din1,
    output reg [DW-1:0] dout1,
    input we1,
    // Port2
    input [AW-1:0] addr2,
    input [DW-1:0] din2,
    output reg [DW-1:0] dout2,
    input we2
);

reg [DW-1:0] mem [0:(1<<AW)-1];

wire [AW-1:0] prot_range = protect_end - protect_start;
wire prot1 = (addr1 - protect_start) <= prot_range;
wire prot2 = (addr2 - protect_start) <= prot_range;

always @(posedge clk) begin
    if (we1 & ~prot1) 
        mem[addr1] <= din1;
    dout1 <= mem[addr1];
    
    if (we2 & ~prot2)
        mem[addr2] <= din2;
    dout2 <= mem[addr2];
end
endmodule