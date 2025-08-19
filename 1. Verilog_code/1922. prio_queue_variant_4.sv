//SystemVerilog
module prio_queue #(parameter DW=8, SIZE=4) (
    input  [DW*SIZE-1:0] data_in,
    output [DW-1:0] data_out
);
    wire [DW-1:0] entries [0:SIZE-1];

    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: entry_split
            assign entries[i] = data_in[(i+1)*DW-1:i*DW];
        end
    endgenerate

    wire [DW-1:0] prio_out [0:SIZE-1];

    // 使用并行前缀加法器算法实现加法器单元
    // 定义8位Kogge-Stone加法器子模块
    function [DW-1:0] kogge_stone_adder;
        input [DW-1:0] a;
        input [DW-1:0] b;
        input c_in;
        reg [DW-1:0] p, g;
        reg [DW:0] c;
        integer j, k, s;
        reg [DW-1:0] gnpg [0:3];
        reg [DW-1:0] temp_g, temp_p;
        begin
            p = a ^ b;
            g = a & b;
            gnpg[0] = g;
            gnpg[1] = {g[DW-2:0],1'b0} | ({p[DW-2:0],1'b0} & g);
            gnpg[2] = {gnpg[1][DW-3:0],2'b00} | ({p[DW-3:0],2'b00} & gnpg[1]);
            gnpg[3] = {gnpg[2][DW-5:0],4'b0000} | ({p[DW-5:0],4'b0000} & gnpg[2]);
            c[0] = c_in;
            for (s = 0; s < DW; s = s + 1) begin
                c[s+1] = gnpg[3][s] | (p[s] & c[s]);
            end
            kogge_stone_adder = p ^ c[DW-1:0];
        end
    endfunction

    // 优先级逻辑，使用并行前缀加法器对输出优先级项进行加法
    wire [DW-1:0] zero_vec = {DW{1'b0}};
    wire [DW-1:0] sel3 = (|entries[3]) ? entries[3] : zero_vec;
    wire [DW-1:0] sel2 = (|entries[2]) ? entries[2] : zero_vec;
    wire [DW-1:0] sel1 = (|entries[1]) ? entries[1] : zero_vec;
    wire [DW-1:0] sel0 = (|entries[0]) ? entries[0] : zero_vec;

    wire [DW-1:0] stage1_sum;
    wire [DW-1:0] stage2_sum;

    assign stage1_sum = kogge_stone_adder(sel0, sel1, 1'b0);
    assign stage2_sum = kogge_stone_adder(sel2, sel3, 1'b0);
    assign data_out   = kogge_stone_adder(stage1_sum, stage2_sum, 1'b0);
endmodule