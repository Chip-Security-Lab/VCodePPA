//SystemVerilog
module priority_encoded_shifter(
    input [7:0] data,
    input [2:0] priority_shift, // Priority-encoded shift amount
    output [7:0] result
);
    reg [7:0] shifted_data;
    
    // Combined priority encoder and shift operation in one always block
    always @(*) begin
        if (priority_shift[2])
            shifted_data = data << 4; // Highest priority
        else if (priority_shift[1])
            shifted_data = data << 2; // Medium priority
        else if (priority_shift[0])
            shifted_data = data << 1; // Lowest priority
        else
            shifted_data = data; // No shift
    end
    
    assign result = shifted_data;
endmodule