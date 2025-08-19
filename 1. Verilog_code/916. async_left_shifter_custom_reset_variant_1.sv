//SystemVerilog
module async_left_shifter_custom_reset #(
    parameter WIDTH = 8,
    parameter RESET_VAL = 8'hA5  // Custom reset pattern
)(
    input                  rstn,
    input      [WIDTH-1:0] din,
    input      [$clog2(WIDTH)-1:0] shift,
    output     [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] barrel_shift_result;
    reg [WIDTH-1:0] shifted_data;
    
    // Implement barrel shifter structure
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: GEN_BARREL
            // Determine shifted bit positions using multiplexers
            wire [$clog2(WIDTH):0] shift_idx;
            wire shifted_bit;
            
            // Calculate source bit index (account for left shift)
            assign shift_idx = i - shift;
            
            // Select appropriate bit based on shift amount
            assign shifted_bit = (shift_idx < WIDTH && shift_idx >= 0) ? din[shift_idx] : 1'b0;
            
            // Assign to output
            assign barrel_shift_result[i] = shifted_bit;
        end
    endgenerate
    
    // Async reset with custom reset value
    always @(*) begin
        if (!rstn)
            shifted_data = RESET_VAL;
        else
            shifted_data = barrel_shift_result;
    end
    
    assign dout = shifted_data;
endmodule