//SystemVerilog
module barrel_shifter #(parameter N=8) (
    input  wire [N-1:0] data_in,
    input  wire [$clog2(N)-1:0] shift_amt,
    output wire [N-1:0] data_out
);

    wire [N-1:0] left_shift_stage [$clog2(N):0];
    wire [N-1:0] right_shift_stage [$clog2(N):0];

    assign left_shift_stage[0]  = data_in;
    assign right_shift_stage[0] = data_in;

    genvar stage;
    generate
        for (stage = 0; stage < $clog2(N); stage = stage + 1) begin : stage_gen
            wire [N-1:0] left_temp, right_temp;
            assign left_temp  = {left_shift_stage[stage][N-1-(1<<stage):0], {1<<stage{1'b0}}};
            assign right_temp = {{1<<stage{1'b0}}, right_shift_stage[stage][N-1:1<<stage]};
            assign left_shift_stage[stage+1]  = shift_amt[stage] ? left_temp  : left_shift_stage[stage];
            assign right_shift_stage[stage+1] = shift_amt[stage] ? right_temp : right_shift_stage[stage];
        end
    endgenerate

    wire [N-1:0] left_final, right_final;
    assign left_final  = left_shift_stage[$clog2(N)];
    assign right_final = right_shift_stage[$clog2(N)];

    assign data_out = left_final | right_final;

endmodule