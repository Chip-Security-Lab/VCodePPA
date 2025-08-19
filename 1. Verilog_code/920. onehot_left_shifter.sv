module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output [WIDTH-1:0] out_data
);
    reg [WIDTH-1:0] shift_result;
    integer i;
    
    // One-hot control uses thermometer encoding for shift control
    always @(*) begin
        shift_result = in_data;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (one_hot_control[i])
                shift_result = in_data << i;
        end
    end
    
    assign out_data = shift_result;
endmodule