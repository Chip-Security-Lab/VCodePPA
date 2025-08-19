//SystemVerilog
module bin2gray_pipeline #(parameter WIDTH = 8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      bin_in,
    input  wire                  bin_in_valid,
    output reg  [WIDTH-1:0]      gray_out,
    output reg                   gray_out_valid
);

    // Stage 1: Input register
    reg [WIDTH-1:0] bin_stage1;
    reg             bin_stage1_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_stage1       <= {WIDTH{1'b0}};
            bin_stage1_valid <= 1'b0;
        end else begin
            bin_stage1       <= bin_in;
            bin_stage1_valid <= bin_in_valid;
        end
    end

    // Stage 2: Bin to shifted value register
    reg [WIDTH-1:0] bin_shift_stage2;
    reg [WIDTH-1:0] bin_stage2;
    reg             bin_stage2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_shift_stage2 <= {WIDTH{1'b0}};
            bin_stage2       <= {WIDTH{1'b0}};
            bin_stage2_valid <= 1'b0;
        end else begin
            bin_stage2       <= bin_stage1;
            bin_shift_stage2 <= bin_stage1 >> 1;
            bin_stage2_valid <= bin_stage1_valid;
        end
    end

    // Stage 3: Gray code output register using conditional sum subtraction
    reg [WIDTH-1:0] gray_stage3;
    reg             gray_stage3_valid;
    wire [WIDTH-1:0] gray_sum_result;
    wire             gray_carry_out;

    conditional_sum_subtractor_8bit u_conditional_sum_subtractor_8bit (
        .a      (bin_stage2),
        .b      (bin_shift_stage2),
        .diff   (gray_sum_result),
        .cout   (gray_carry_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage3       <= {WIDTH{1'b0}};
            gray_stage3_valid <= 1'b0;
        end else begin
            gray_stage3       <= gray_sum_result;
            gray_stage3_valid <= bin_stage2_valid;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out       <= {WIDTH{1'b0}};
            gray_out_valid <= 1'b0;
        end else begin
            gray_out       <= gray_stage3;
            gray_out_valid <= gray_stage3_valid;
        end
    end

endmodule

// 8-bit Conditional Sum Subtractor
module conditional_sum_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff,
    output wire       cout
);
    // Invert b and add 1 for subtraction: a - b = a + (~b) + 1
    wire [7:0] b_invert;
    assign b_invert = ~b;

    wire [7:0] sum_stage0, sum_stage1, sum_stage2, sum_stage3;
    wire       carry_stage0, carry_stage1, carry_stage2, carry_stage3;

    // Stage 0: LSB 2 bits
    assign {carry_stage0, sum_stage0[1:0]} = {1'b0, a[1:0]} + {1'b0, b_invert[1:0]} + 2'b01;
    // Stage 1: Bits 2-3
    assign {carry_stage1, sum_stage1[3:2]} = {1'b0, a[3:2]} + {1'b0, b_invert[3:2]} + carry_stage0;
    // Stage 2: Bits 4-5
    assign {carry_stage2, sum_stage2[5:4]} = {1'b0, a[5:4]} + {1'b0, b_invert[5:4]} + carry_stage1;
    // Stage 3: Bits 6-7
    assign {carry_stage3, sum_stage3[7:6]} = {1'b0, a[7:6]} + {1'b0, b_invert[7:6]} + carry_stage2;

    assign diff[1:0] = sum_stage0[1:0];
    assign diff[3:2] = sum_stage1[3:2];
    assign diff[5:4] = sum_stage2[5:4];
    assign diff[7:6] = sum_stage3[7:6];
    assign cout      = carry_stage3;

endmodule