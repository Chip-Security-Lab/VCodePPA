module async_rst_low_comb #(parameter WIDTH=16)(
    input wire rst_n,
    input wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
assign out_data = rst_n ? in_data : {WIDTH{1'b0}};
endmodule
