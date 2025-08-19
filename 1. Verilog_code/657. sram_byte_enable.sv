module sram_byte_enable #(
    parameter BYTES = 4  // 32-bit with 4 byte lanes
)(
    input clk,
    input cs,
    input [BYTES-1:0] we,
    input [7:0] addr,
    input [BYTES*8-1:0] din,
    output [BYTES*8-1:0] dout
);
localparam DW = BYTES*8;
reg [7:0] mem [0:255][0:BYTES-1];

genvar i;
generate
for (i=0; i<BYTES; i=i+1) begin : gen_byte_lanes
    always @(posedge clk) begin
        if (cs & we[i]) begin
            mem[addr][i] <= din[i*8+:8];
        end
    end
    assign dout[i*8+:8] = mem[addr][i];
end
endgenerate
endmodule