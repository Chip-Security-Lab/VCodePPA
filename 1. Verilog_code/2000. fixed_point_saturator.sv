module fixed_point_saturator #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire signed [IN_WIDTH-1:0] in_data,
    output reg signed [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire signed [OUT_WIDTH-1:0] max_val = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    wire signed [OUT_WIDTH-1:0] min_val = {1'b1, {(OUT_WIDTH-1){1'b0}}};
    wire upper_bits_same = &(in_data[IN_WIDTH-1:OUT_WIDTH-1]) | ~|in_data[IN_WIDTH-1:OUT_WIDTH-1];
    
    always @* begin
        overflow = !upper_bits_same;
        
        if (in_data[IN_WIDTH-1] == 0 && overflow) begin
            out_data = max_val;
        end else if (in_data[IN_WIDTH-1] == 1 && overflow) begin
            out_data = min_val;
        end else begin
            out_data = in_data[OUT_WIDTH-1:0];
        end
    end
endmodule