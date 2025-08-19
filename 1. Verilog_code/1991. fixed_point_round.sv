module fixed_point_round #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire [IN_WIDTH-1:0] in_data,
    output reg [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire round_bit = (IN_WIDTH > OUT_WIDTH) ? in_data[IN_WIDTH-OUT_WIDTH-1] : 0;
    reg [OUT_WIDTH:0] rounded;
    
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){in_data[IN_WIDTH-1]}}, in_data};
            overflow = 0;
        end else begin
            rounded = in_data[IN_WIDTH-1:IN_WIDTH-OUT_WIDTH] + round_bit;
            out_data = rounded[OUT_WIDTH-1:0];
            overflow = rounded[OUT_WIDTH] != rounded[OUT_WIDTH-1];
        end
    end
endmodule