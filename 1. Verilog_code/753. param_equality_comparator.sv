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
    
    // Registered output with enable control
    always @(posedge clock) begin
        if (reset) begin
            match_flag <= 1'b0;
        end else if (enable) begin
            match_flag <= is_equal;
        end
        // Hold previous value when not enabled
    end
endmodule