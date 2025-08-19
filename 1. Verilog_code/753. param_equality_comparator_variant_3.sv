//SystemVerilog
module param_equality_comparator #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg match_flag
);
    // Internal comparison wire
    wire is_equal;
    
    // Asynchronous comparison logic
    assign is_equal = (data_in_a == data_in_b);
    
    // Control signals for if-else structure
    reg [1:0] control;
    
    // Registered output with if-else based control
    always @(posedge clock) begin
        // Create a control word from reset and enable signals
        control = {reset, enable};
        
        if (control == 2'b10 || control == 2'b11) begin
            match_flag <= 1'b0;      // Reset has priority
        end else if (control == 2'b01) begin
            match_flag <= is_equal;  // Enable and not reset
        end else if (control == 2'b00) begin
            match_flag <= match_flag; // Hold previous value
        end else begin
            match_flag <= match_flag; // Default case for completeness
        end
    end
endmodule