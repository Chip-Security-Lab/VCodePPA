//SystemVerilog
module async_case_decoder #(
    parameter AW = 3,
    parameter DW = 8
)(
    input wire [AW-1:0] address,
    output reg [DW-1:0] select
);

    // Binary complement subtraction implementation
    reg [DW-1:0] complement_result;
    reg [DW-1:0] base_value;
    reg [DW-1:0] complement_mask;
    
    // Generate complement mask based on address
    always @(*) begin
        base_value = 8'b00000001;
        complement_mask = 8'b11111111;
        
        // Shift base value by address amount
        base_value = base_value << address;
        
        // Apply complement operation
        complement_result = base_value ^ complement_mask;
        
        // Final result is the complement of the complement (original value)
        select = ~complement_result;
    end

endmodule