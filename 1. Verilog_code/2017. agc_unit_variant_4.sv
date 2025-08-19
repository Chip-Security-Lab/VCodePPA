//SystemVerilog
module agc_unit #(
    parameter W = 16
) (
    input wire clk,
    input wire [W-1:0] in,
    output reg [W-1:0] out
);

    // Peak detection pipeline registers
    reg [W+1:0] peak_reg = { (W+2){1'b0} };
    reg [W+1:0] peak_shifted_reg;
    reg [W+1:0] peak_sub_reg;
    reg in_gt_peak_reg;
    reg [W+1:0] peak_candidate_reg;
    reg [W+1:0] peak_next_reg;

    // Output calculation pipeline registers
    reg [W+1:0] denominator_reg;
    reg [W+15:0] numerator_reg;
    reg [W-1:0] out_next_reg;

    // 8-bit Parallel Prefix Adder (Kogge-Stone) wires and logic for peak_sub_stage1 and peak_candidate_reg
    wire [W+1:0] peak_shifted_stage1;
    assign peak_shifted_stage1 = peak_reg >> 3;

    wire [W+1:0] peak_sub_stage1;
    parallel_prefix_subtractor #(.WIDTH(W+2)) u_peak_subtractor (
        .a(peak_reg),
        .b(peak_shifted_stage1),
        .diff(peak_sub_stage1)
    );

    // Stage 2: Peak compare and select
    wire in_gt_peak_stage2;
    assign in_gt_peak_stage2 = (in > peak_sub_reg);
    wire [W+1:0] peak_candidate_stage2;
    wire [W+1:0] in_ext;
    assign in_ext = {2'b00, in};
    parallel_prefix_mux #(.WIDTH(W+2)) u_peak_candidate_mux (
        .sel(in_gt_peak_reg),
        .a(in_ext),
        .b(peak_sub_reg),
        .y(peak_candidate_stage2)
    );
    wire [W+1:0] peak_next_stage2;
    assign peak_next_stage2 = peak_candidate_reg;

    // Stage 3: Output calculation numerator and denominator
    wire [W+1:0] denominator_stage3;
    assign denominator_stage3 = (peak_next_reg != 0) ? peak_next_reg : {{(W+1){1'b0}}, 1'b1};
    wire [W+15:0] numerator_stage3;
    parallel_prefix_multiplier #(.AW(W), .BW(16)) u_numerator_multiplier (
        .a(in),
        .b(16'd32767),
        .prod(numerator_stage3)
    );

    // Stage 4: Output calculation division
    wire [W-1:0] out_next_stage4;
    assign out_next_stage4 = numerator_reg / denominator_reg;

    // Pipeline registers
    always @(posedge clk) begin
        // Stage 1 registers
        peak_shifted_reg   <= peak_shifted_stage1;
        peak_sub_reg       <= peak_sub_stage1;

        // Stage 2 registers
        in_gt_peak_reg     <= (in > peak_sub_reg);
        peak_candidate_reg <= peak_candidate_stage2;
        peak_next_reg      <= peak_candidate_reg;

        // Stage 3 registers
        denominator_reg    <= (peak_next_reg != 0) ? peak_next_reg : {{(W+1){1'b0}}, 1'b1};
        numerator_reg      <= numerator_stage3;

        // Stage 4 registers
        out_next_reg       <= out_next_stage4;

        // Update peak register
        peak_reg           <= peak_next_reg;

        // Output register
        out                <= out_next_reg;
    end

endmodule

// 8-bit Parallel Prefix Adder (Kogge-Stone) for subtraction (a - b)
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_comp;
    wire [WIDTH:0] carry; // carry[0] is the input carry (set to 1 for subtraction)
    assign b_comp = ~b;
    assign carry[0] = 1'b1;

    parallel_prefix_adder #(.WIDTH(WIDTH)) u_kogge_stone_sub (
        .a(a),
        .b(b_comp),
        .cin(carry[0]),
        .sum(diff),
        .cout()
    );
endmodule

// 8-bit Parallel Prefix Adder (Kogge-Stone)
module parallel_prefix_adder #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gp_gen
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Parallel prefix computation (Kogge-Stone logic)
    wire [WIDTH-1:0] G [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] P [0:$clog2(WIDTH)];

    // Level 0
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : level0
            assign G[0][i] = g[i];
            assign P[0][i] = p[i];
        end
    endgenerate

    genvar level, k;
    generate
        for (level = 1; level <= $clog2(WIDTH); level = level + 1) begin : levels
            for (k = 0; k < WIDTH; k = k + 1) begin : stage
                if (k < (1 << (level-1))) begin
                    assign G[level][k] = G[level-1][k];
                    assign P[level][k] = P[level-1][k];
                end else begin
                    assign G[level][k] = G[level-1][k] | (P[level-1][k] & G[level-1][k-(1<<(level-1))]);
                    assign P[level][k] = P[level-1][k] & P[level-1][k-(1<<(level-1))];
                end
            end
        end
    endgenerate

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_out
            assign c[i+1] = G[$clog2(WIDTH)][i] | (P[$clog2(WIDTH)][i] & c[0]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    assign cout = c[WIDTH];
endmodule

// Mux module for parallel prefix adder output selection
module parallel_prefix_mux #(
    parameter WIDTH = 8
) (
    input  wire sel,
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    assign y = sel ? a : b;
endmodule

// 8x16 Parallel Prefix Multiplier (uses simple assign for multiplication, as multiplier PPA is not the focus)
module parallel_prefix_multiplier #(
    parameter AW = 8,
    parameter BW = 16
) (
    input  wire [AW-1:0] a,
    input  wire [BW-1:0] b,
    output wire [AW+BW-1:0] prod
);
    assign prod = a * b;
endmodule