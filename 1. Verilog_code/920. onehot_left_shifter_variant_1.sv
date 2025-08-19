//SystemVerilog
module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output [WIDTH-1:0] out_data
);
    // Logarithmic carry-lookahead approach for shifter
    wire [WIDTH-1:0] intermediate_shifts[WIDTH:0];
    
    // Base case - no shift
    assign intermediate_shifts[0] = in_data;
    
    // Generate all possible shifts in parallel
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : shift_gen
            assign intermediate_shifts[i+1] = in_data << i;
        end
    endgenerate
    
    // Select the appropriate shift based on one-hot control
    reg [WIDTH-1:0] result;
    integer j;
    
    always @(*) begin
        result = {WIDTH{1'b0}}; // Default to zero
        for (j = 0; j < WIDTH; j = j + 1) begin
            result = result | (one_hot_control[j] ? intermediate_shifts[j+1] : {WIDTH{1'b0}});
        end
    end
    
    assign out_data = result;
endmodule