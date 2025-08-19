module dual_rail_encoder #(parameter WIDTH = 4) (
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire [2*WIDTH-1:0] dual_rail_out
);
    // Dual rail encoding: for each bit, 
    // send complementary pair {bit, ~bit}
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_dual_rail
            assign dual_rail_out[2*i]   = data_in[i] & valid_in;
            assign dual_rail_out[2*i+1] = ~data_in[i] & valid_in;
        end
    endgenerate
endmodule