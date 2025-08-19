//SystemVerilog
module list2array #(parameter DW=8, MAX_LEN=8) (
    input clk, rst_n,
    input [DW-1:0] node_data,
    input node_valid,
    output [DW*MAX_LEN-1:0] array_out,
    output reg [3:0] length
);
    reg [DW-1:0] mem [0:MAX_LEN-1];
    reg [3:0] idx;
    integer i;

    // Pipeline registers for adder outputs (cut critical path)
    reg [3:0] idx_hc_sum_reg;
    reg idx_hc_cout_reg;
    reg [3:0] length_hc_sum_reg;
    reg length_hc_cout_reg;
    reg idx_eq_maxlen_1_reg;
    reg length_eq_maxlen_reg;

    // Adder outputs (pre-pipeline)
    wire [3:0] idx_hc_sum;
    wire idx_hc_cout;
    wire [3:0] length_hc_sum;
    wire length_hc_cout;

    // Han-Carlson 4-bit adder for idx
    han_carlson_adder_4bit idx_hc_adder (
        .a(idx),
        .b(4'd1),
        .cin(1'b0),
        .sum(idx_hc_sum),
        .cout(idx_hc_cout)
    );

    // Han-Carlson 4-bit adder for length
    han_carlson_adder_4bit length_hc_adder (
        .a(length),
        .b(4'd1),
        .cin(1'b0),
        .sum(length_hc_sum),
        .cout(length_hc_cout)
    );

    // Pipeline - capture adder results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx_hc_sum_reg <= 4'd0;
            idx_hc_cout_reg <= 1'b0;
            length_hc_sum_reg <= 4'd0;
            length_hc_cout_reg <= 1'b0;
            idx_eq_maxlen_1_reg <= 1'b0;
            length_eq_maxlen_reg <= 1'b0;
        end else begin
            idx_hc_sum_reg <= idx_hc_sum;
            idx_hc_cout_reg <= idx_hc_cout;
            length_hc_sum_reg <= length_hc_sum;
            length_hc_cout_reg <= length_hc_cout;
            idx_eq_maxlen_1_reg <= (idx == MAX_LEN-1);
            length_eq_maxlen_reg <= (length == MAX_LEN);
        end
    end

    // Pipeline outputs are used for next state computation
    wire [3:0] idx_next_piped;
    wire [3:0] length_next_piped;

    assign idx_next_piped = idx_eq_maxlen_1_reg ? 4'd0 : idx_hc_sum_reg;
    assign length_next_piped = length_eq_maxlen_reg ? MAX_LEN[3:0] : length_hc_sum_reg;

    // Main register update, using pipelined outputs, insert one cycle stall for node_valid
    reg node_valid_d;
    reg [DW-1:0] node_data_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx <= 4'd0;
            length <= 4'd0;
            node_valid_d <= 1'b0;
            node_data_d <= {DW{1'b0}};
            for (i = 0; i < MAX_LEN; i = i + 1) begin
                mem[i] <= {DW{1'b0}};
            end
        end else begin
            node_valid_d <= node_valid;
            node_data_d <= node_data;
            if (node_valid_d) begin
                mem[idx] <= node_data_d;
                idx <= idx_next_piped;
                length <= length_next_piped;
            end
        end
    end

    genvar g;
    generate
        for (g = 0; g < MAX_LEN; g = g + 1) begin: mem_to_array
            assign array_out[g*DW +: DW] = mem[g];
        end
    endgenerate
endmodule

// Han-Carlson 4-bit adder module
module han_carlson_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    // Black and Gray Cell Functions
    function [1:0] black_cell(input gk, pk, gj, pj);
        black_cell = {gk | (pk & gj), pk & pj};
    endfunction

    function gray_cell(input gk, pk, gj);
        gray_cell = gk | (pk & gj);
    endfunction

    // Stage 1
    wire [3:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign {g1[1], p1[1]} = black_cell(g[1], p[1], g[0], p[0]);
    assign {g1[2], p1[2]} = black_cell(g[2], p[2], g[1], p[1]);
    assign {g1[3], p1[3]} = black_cell(g[3], p[3], g[2], p[2]);

    // Stage 2
    wire [3:0] g2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign g2[2] = gray_cell(g1[2], p1[2], g[0]);
    assign g2[3] = gray_cell(g1[3], p1[3], g[1]);

    // Stage 3 (Final Carry)
    wire [4:0] carry;
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g2[1] | (p1[1] & carry[0]);
    assign carry[3] = g2[2] | (p1[2] & carry[0]);
    assign carry[4] = g2[3] | (p1[3] & carry[0]);

    assign sum = p ^ carry[3:0];
    assign cout = carry[4];
endmodule