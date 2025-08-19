//SystemVerilog
module dual_rail_encoder #(parameter WIDTH = 4) (
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire [2*WIDTH-1:0] dual_rail_out
);
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_dual_rail
            assign dual_rail_out[2*i]   = valid_in & data_in[i];
            assign dual_rail_out[2*i+1] = valid_in & (~data_in[i]);
        end
    endgenerate
endmodule