//SystemVerilog
//======================================================================
// Serial Input Ring Counter with Improved Data Path Structure
//======================================================================
module serial_in_ring_counter (
    input  wire       clk,     // System clock
    input  wire       rst,     // Synchronous reset
    input  wire       ser_in,  // Serial input bit
    output reg  [3:0] count    // Ring counter output
);

    // Optimized data path with forward register retiming
    reg [2:0] shift_stage;
    
    // Output formation stage - Combines values for final output
    // Retimed to directly use ser_in instead of ser_in_reg
    always @(posedge clk) begin
        if (rst)
            count <= 4'b0001; // Initial value on reset
        else
            count <= {shift_stage, ser_in}; // Direct use of ser_in improves timing
    end
    
    // Shift register stage moved after the output stage in the data flow
    // This spreads the timing more evenly through the design
    always @(posedge clk) begin
        if (rst)
            shift_stage <= 3'b000;
        else
            shift_stage <= count[2:0];
    end

endmodule