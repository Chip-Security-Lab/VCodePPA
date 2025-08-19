module async_onehot_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] priority_onehot,
    output valid
);
    // One-hot priority encoder
    wire [WIDTH-1:0] masked;
    assign masked[WIDTH-1] = data_in[WIDTH-1];
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1)
            assign masked[i] = data_in[i] & ~(|data_in[WIDTH-1:i+1]);
    endgenerate
    assign priority_onehot = masked;
    assign valid = |data_in;
endmodule