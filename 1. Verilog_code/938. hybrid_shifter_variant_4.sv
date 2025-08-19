//SystemVerilog
module hybrid_shifter #(
    parameter DATA_W = 16,
    parameter SHIFT_W = 4
)(
    input [DATA_W-1:0] din,
    input [SHIFT_W-1:0] shift,
    input dir,  // 0-left, 1-right
    input mode,  // 0-logical, 1-arithmetic
    output reg [DATA_W-1:0] dout
);
    
    always @(*) begin
        dout = dir ? (mode ? $signed(din) >>> shift : din >> shift) : din << shift;
    end
    
endmodule