//SystemVerilog
// Top-level module: exp_map
// Function: Computes y = (1 << x[W-1:4]) + (x[3:0] << (x[W-1:4]-4))
// Structured pipeline for clear dataflow, improved timing, and PPA

module exp_map #(parameter W = 16)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [W-1:0]          x,
    output wire [W-1:0]          y
);

    // Pipeline Stage 1: Extract and register input segments
    reg  [W-5:0]                 stage1_x_high;
    reg  [3:0]                   stage1_x_low;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_x_high <= {W-4{1'b0}};
            stage1_x_low  <= 4'b0;
        end else begin
            stage1_x_high <= x[W-1:4];
            stage1_x_low  <= x[3:0];
        end
    end

    // Pipeline Stage 2: Compute and register shift_one and x_high_minus4
    wire [W-1:0]                 stage2_exp_high;
    wire [W-5:0]                 stage2_x_high;
    wire [3:0]                   stage2_x_low;
    wire [W-5:0]                 stage2_x_high_minus4;

    // Submodule: shift_one
    shift_one #(.W(W)) u_shift_one (
        .shift_amt (stage1_x_high),
        .result    (stage2_exp_high)
    );

    // Submodule: subtractor
    subtractor #(.WIDTH(W-4)) u_subtractor (
        .a         (stage1_x_high),
        .b         ({{(W-8){1'b0}}, 4'd4}),
        .diff      (stage2_x_high_minus4)
    );

    // Register outputs of stage 2 for next pipeline stage
    reg  [W-1:0]                 stage2_exp_high_r;
    reg  [W-5:0]                 stage2_x_high_minus4_r;
    reg  [3:0]                   stage2_x_low_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_exp_high_r      <= {W{1'b0}};
            stage2_x_high_minus4_r <= {W-4{1'b0}};
            stage2_x_low_r         <= 4'b0;
        end else begin
            stage2_exp_high_r      <= stage2_exp_high;
            stage2_x_high_minus4_r <= stage2_x_high_minus4;
            stage2_x_low_r         <= stage1_x_low;
        end
    end

    // Pipeline Stage 3: Compute and register exp_low
    wire [W-1:0]                 stage3_exp_low;
    shift_low #(.W(W)) u_shift_low (
        .data_in   (stage2_x_low_r),
        .shift_amt (stage2_x_high_minus4_r),
        .result    (stage3_exp_low)
    );

    // Register outputs of stage 3 for next pipeline stage
    reg  [W-1:0]                 stage3_exp_high_r;
    reg  [W-1:0]                 stage3_exp_low_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_exp_high_r <= {W{1'b0}};
            stage3_exp_low_r  <= {W{1'b0}};
        end else begin
            stage3_exp_high_r <= stage2_exp_high_r;
            stage3_exp_low_r  <= stage3_exp_low;
        end
    end

    // Pipeline Stage 4: Final adder
    wire [W-1:0]                 stage4_sum;
    adder #(.W(W)) u_adder (
        .a   (stage3_exp_high_r),
        .b   (stage3_exp_low_r),
        .sum (stage4_sum)
    );

    // Output register (optional, can be removed for pure combinational y)
    reg  [W-1:0]                 y_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_r <= {W{1'b0}};
        else
            y_r <= stage4_sum;
    end

    assign y = y_r;

endmodule

// ---------------------------------------------------------------------------
// Submodule: shift_one
// Function: Computes (1 << shift_amt)
// ---------------------------------------------------------------------------
module shift_one #(parameter W = 16)(
    input  wire [W-5:0] shift_amt,
    output wire [W-1:0] result
);
    assign result = (shift_amt < W) ? ({{(W-1){1'b0}},1'b1} << shift_amt) : {W{1'b0}};
endmodule

// ---------------------------------------------------------------------------
// Submodule: subtractor
// Function: Computes (a - b)
// ---------------------------------------------------------------------------
module subtractor #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);
    assign diff = a - b;
endmodule

// ---------------------------------------------------------------------------
// Submodule: shift_low
// Function: Computes (data_in << shift_amt)
// data_in is 4 bits, output is W bits
// ---------------------------------------------------------------------------
module shift_low #(parameter W = 16)(
    input  wire [3:0]           data_in,
    input  wire [W-5:0]         shift_amt,
    output wire [W-1:0]         result
);
    assign result = (shift_amt < W) ? ({{(W-4){1'b0}},data_in} << shift_amt) : {W{1'b0}};
endmodule

// ---------------------------------------------------------------------------
// Submodule: adder
// Function: Computes (a + b)
// ---------------------------------------------------------------------------
module adder #(parameter W = 16)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] sum
);
    assign sum = a + b;
endmodule