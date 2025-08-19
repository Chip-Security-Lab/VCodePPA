module fixed_point_truncate #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire [IN_WIDTH-1:0] in_data,
    output reg [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire sign = in_data[IN_WIDTH-1];
    
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){sign}}, in_data};
            overflow = 0;
        end else begin
            out_data = in_data[OUT_WIDTH-1:0];
            overflow = (sign && !(&in_data[IN_WIDTH-1:OUT_WIDTH-1])) || 
                       (!sign && |in_data[IN_WIDTH-1:OUT_WIDTH]);
        end
    end
endmodule