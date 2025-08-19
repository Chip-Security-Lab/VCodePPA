//SystemVerilog
module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output [WIDTH-1:0] out_data
);
    wire [WIDTH-1:0] shift_masks [WIDTH-1:0];
    wire [WIDTH-1:0] shift_results [WIDTH-1:0];
    
    // Generate all possible shift results in parallel
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_shifts
            assign shift_masks[i] = {WIDTH{one_hot_control[i]}};
            assign shift_results[i] = shift_masks[i] & (in_data << i);
        end
    endgenerate
    
    // Combine results using reduction OR
    reg [WIDTH-1:0] final_result;
    integer j;
    always @(*) begin
        final_result = {WIDTH{1'b0}};
        for (j = 0; j < WIDTH; j = j + 1) begin
            final_result = final_result | shift_results[j];
        end
    end
    
    assign out_data = final_result;
endmodule