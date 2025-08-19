//SystemVerilog
module sram_latency #(
    parameter DW = 8,
    parameter AW = 4,
    parameter LATENCY = 2
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
wire [DW-1:0] sub_result;
wire [DW:0] carry_chain;
integer i;

// 优化后的先行借位减法器
assign carry_chain[0] = 1'b1;
genvar j;
generate
    for (j = 0; j < DW; j = j + 1) begin : SUB_GEN
        wire temp_carry;
        assign temp_carry = (~mem[addr][j] & din[j]) | 
                          ((~mem[addr][j] | din[j]) & carry_chain[j]);
        assign sub_result[j] = mem[addr][j] ^ din[j] ^ carry_chain[j];
        assign carry_chain[j+1] = temp_carry;
    end
endgenerate

always @(posedge clk) begin
    if (ce) begin
        if (we) mem[addr] <= din;
        pipe_reg[0] <= sub_result;
        for (i = 1; i < LATENCY; i = i + 1) begin
            pipe_reg[i] <= pipe_reg[i-1];
        end
    end
end

assign dout = pipe_reg[LATENCY-1];

endmodule