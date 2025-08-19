//SystemVerilog
module configurable_parity #(
    parameter WIDTH = 16
)(
    input clk,
    input cfg_parity_type, // 0: even, 1: odd
    input [WIDTH-1:0] data,
    output reg parity
);
    // LUT-based parity calculation
    reg [3:0] lut_parity;
    reg [WIDTH/2-1:0] partial_parity;
    
    // Calculate 2-bit parity using lookup table approach
    always @(*) begin
        for (int i = 0; i < WIDTH/2; i = i + 1) begin
            case (data[i*2+:2])
                2'b00: lut_parity[i%4] = 1'b0;
                2'b01: lut_parity[i%4] = 1'b1;
                2'b10: lut_parity[i%4] = 1'b1;
                2'b11: lut_parity[i%4] = 1'b0;
                default: lut_parity[i%4] = 1'b0;
            endcase
            partial_parity[i] = lut_parity[i%4];
        end
    end
    
    // Combine partial results
    wire calc_parity = ^partial_parity;
    
    always @(posedge clk)
        parity <= calc_parity ^ ~cfg_parity_type;
endmodule