//SystemVerilog
module output_enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire oe,       // Output enable
    output wire [3:0] data
);
    reg [3:0] count_reg;
    reg oe_reg;
    
    // Register the output enable signal
    always @(posedge clock) begin
        oe_reg <= oe;
    end
    
    // Assign data using registered output enable
    assign data = oe_reg ? count_reg : 4'bz;
    
    // Optimized state transition logic with moved register
    always @(posedge clock) begin
        if (reset)
            count_reg <= 4'b0001;
        else
            // Explicit shift logic to avoid concatenation operator
            case (count_reg)
                4'b0001: count_reg <= 4'b0010;
                4'b0010: count_reg <= 4'b0100;
                4'b0100: count_reg <= 4'b1000;
                4'b1000: count_reg <= 4'b0001;
                default: count_reg <= 4'b0001; // Prevent invalid states
            endcase
    end
endmodule