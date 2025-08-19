//SystemVerilog
module priority_encoded_shifter(
    input [7:0] data,
    input [2:0] priority_shift, // Priority-encoded shift amount
    output [7:0] result
);
    reg [7:0] shifted_data;
    reg [2:0] actual_shift;
    
    // Priority encoder for shift amount using case statement
    always @(*) begin
        case (priority_shift)
            3'b1??: actual_shift = 3'd4; // Highest priority (bit 2 set)
            3'b01?: actual_shift = 3'd2; // Medium priority (bit 1 set, bit 2 clear)
            3'b001: actual_shift = 3'd1; // Lowest priority (bit 0 set, bits 1-2 clear)
            default: actual_shift = 3'd0; // No shift (all bits clear)
        endcase
    end
    
    // Apply the shift - combined with output assignment to reduce logic
    assign result = data << actual_shift;
endmodule