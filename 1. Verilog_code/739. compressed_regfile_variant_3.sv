//SystemVerilog
module compressed_regfile #(
    parameter PACKED_WIDTH = 16,
    parameter UNPACKED_WIDTH = 32
)(
    input clk,
    input wr_en,
    input [3:0] addr,
    input [PACKED_WIDTH-1:0] din,
    input [3:0] sub_a,      // First operand for subtraction
    input [3:0] sub_b,      // Second operand for subtraction
    output [UNPACKED_WIDTH-1:0] dout,
    output [3:0] sub_result // Result of subtraction
);
reg [PACKED_WIDTH-1:0] storage [0:15];
wire [UNPACKED_WIDTH-1:0] expansion = 
    {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[addr]};

// Borrow-based 4-bit subtractor implementation
wire [3:0] borrow;
wire [3:0] diff;

// First bit subtraction
assign diff[0] = sub_a[0] ^ sub_b[0];
assign borrow[0] = (~sub_a[0] & sub_b[0]);

// Remaining bits with borrow propagation
genvar i;
generate
    for (i = 1; i < 4; i = i + 1) begin : sub_gen
        wire a_borrow = (~sub_a[i] & sub_b[i]);
        wire a_or_b_borrow = (~sub_a[i] | sub_b[i]) & borrow[i-1];
        assign diff[i] = sub_a[i] ^ sub_b[i] ^ borrow[i-1];
        assign borrow[i] = a_borrow | a_or_b_borrow;
    end
endgenerate

assign sub_result = diff;

always @(posedge clk) begin
    if (wr_en) storage[addr] <= din;
end

assign dout = expansion;
endmodule