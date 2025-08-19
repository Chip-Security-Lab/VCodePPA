module compressed_regfile #(
    parameter PACKED_WIDTH = 16,
    parameter UNPACKED_WIDTH = 32
)(
    input clk,
    input wr_en,
    input [3:0] addr,
    input [PACKED_WIDTH-1:0] din,
    output [UNPACKED_WIDTH-1:0] dout
);
reg [PACKED_WIDTH-1:0] storage [0:15];
wire [UNPACKED_WIDTH-1:0] expansion = 
    {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, storage[addr]};

always @(posedge clk) begin
    if (wr_en) storage[addr] <= din;
end

assign dout = expansion;
endmodule