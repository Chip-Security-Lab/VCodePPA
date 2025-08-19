module q_format_adjuster #(parameter IN_INT=8, IN_FRAC=8, OUT_INT=4, OUT_FRAC=12)(
    input wire [IN_INT+IN_FRAC-1:0] in_data,
    output reg [OUT_INT+OUT_FRAC-1:0] out_data,
    output reg overflow
);
    always @* begin
        if (IN_FRAC <= OUT_FRAC) begin
            out_data = {{OUT_INT{in_data[IN_INT+IN_FRAC-1]}}, in_data} << (OUT_FRAC - IN_FRAC);
            overflow = |(in_data[IN_INT+IN_FRAC-1:IN_FRAC+OUT_INT]);
        end else begin
            out_data = {{OUT_INT{in_data[IN_INT+IN_FRAC-1]}}, in_data[IN_INT+IN_FRAC-1:IN_FRAC-OUT_FRAC]};
            overflow = 0;
        end
    end
endmodule