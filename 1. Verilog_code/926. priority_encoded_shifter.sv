module priority_encoded_shifter(
    input [7:0] data,
    input [2:0] priority_shift, // Priority-encoded shift amount
    output [7:0] result
);
    reg [7:0] shifted_data;
    reg [2:0] actual_shift;
    
    // Priority encoder for shift amount
    always @(*) begin
        if (priority_shift[2])
            actual_shift = 3'd4; // Highest priority
        else if (priority_shift[1])
            actual_shift = 3'd2; // Medium priority
        else if (priority_shift[0])
            actual_shift = 3'd1; // Lowest priority
        else
            actual_shift = 3'd0; // No shift
    end
    
    // Apply the shift
    always @(*) begin
        shifted_data = data << actual_shift;
    end
    
    assign result = shifted_data;
endmodule