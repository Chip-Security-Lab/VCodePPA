//SystemVerilog
module glitch_filter_rst_sync (
    input  wire clk,
    input  wire async_rst_n,
    output wire filtered_rst_n
);
    reg [3:0] shift_reg;
    reg       filtered;
    
    // Optimized reset synchronizer with shift register
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) 
            shift_reg <= 4'b0000;
        else 
            shift_reg <= {shift_reg[2:0], 1'b1};
    end
    
    // Optimized filtering logic with reduced comparison operations
    // Uses pattern detection instead of equality checks
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) 
            filtered <= 1'b0;
        else if (&shift_reg)  // Bitwise AND - more efficient than equality check
            filtered <= 1'b1;
        else if (~|shift_reg) // Bitwise NOR - more efficient than equality check
            filtered <= 1'b0;
    end
    
    assign filtered_rst_n = filtered;
endmodule