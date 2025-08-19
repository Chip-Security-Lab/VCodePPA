module sram_latency #(
    parameter DW = 8,
    parameter AW = 4,
    parameter LATENCY = 3
)(
    input clk,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg [0:LATENCY-1];
integer i;

always @(posedge clk) begin
    if (ce) begin
        if (we) mem[addr] <= din;
        pipe_reg[0] <= mem[addr];
        for (i=1; i<LATENCY; i=i+1) begin
            pipe_reg[i] <= pipe_reg[i-1];
        end
    end
end

assign dout = pipe_reg[LATENCY-1];
endmodule