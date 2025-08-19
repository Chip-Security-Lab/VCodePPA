//SystemVerilog
module rotate_left_async #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    input  [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] mux_stage [$clog2(WIDTH):0];
    integer i;

    assign mux_stage[0] = din;

    genvar stage;
    generate
        for (stage = 0; stage < $clog2(WIDTH); stage = stage + 1) begin : gen_barrel
            wire [WIDTH-1:0] left_shifted;
            assign left_shifted = {mux_stage[stage][WIDTH-(1<<stage)-1:0], mux_stage[stage][WIDTH-1:WIDTH-(1<<stage)]};
            assign mux_stage[stage+1] = shift[stage] ? left_shifted : mux_stage[stage];
        end
    endgenerate

    assign dout = mux_stage[$clog2(WIDTH)];
endmodule