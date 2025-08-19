//SystemVerilog
// Top-level shift_pipeline module with hierarchical submodules
module shift_pipeline #(
    parameter WIDTH = 8,
    parameter STAGES = 3
) (
    input                  clk,
    input  [WIDTH-1:0]     din,
    output [WIDTH-1:0]     dout
);

    // Internal signals for connecting pipeline stages
    wire [WIDTH-1:0] stage0_out;
    wire [WIDTH-1:0] stage1_out;
    wire [WIDTH-1:0] stage2_out;

    // Stage 0: First shift and register stage
    shift_stage_lut #(
        .WIDTH(WIDTH)
    ) u_stage0 (
        .clk(clk),
        .din(din),
        .dout(stage0_out)
    );

    // Stage 1: Second shift and register stage, instantiated if STAGES > 1
    generate
        if (STAGES > 1) begin : gen_stage1
            shift_stage_lut #(
                .WIDTH(WIDTH)
            ) u_stage1 (
                .clk(clk),
                .din(stage0_out),
                .dout(stage1_out)
            );
        end
    endgenerate

    // Stage 2: Third shift and register stage, instantiated if STAGES > 2
    generate
        if (STAGES > 2) begin : gen_stage2
            shift_stage_lut #(
                .WIDTH(WIDTH)
            ) u_stage2 (
                .clk(clk),
                .din(stage1_out),
                .dout(stage2_out)
            );
        end
    endgenerate

    // Output selection logic based on STAGES parameter
    assign dout = (STAGES == 1) ? stage0_out :
                  (STAGES == 2) ? stage1_out : stage2_out;

endmodule

// ----------------------------------------------------------
// shift_stage_lut: Single pipeline stage with left shift using LUT-based subtractor and register
// ----------------------------------------------------------
module shift_stage_lut #(
    parameter WIDTH = 8
) (
    input                  clk,
    input  [WIDTH-1:0]     din,
    output reg [WIDTH-1:0] dout
);

    wire [WIDTH-1:0] shifted_data;
    wire [WIDTH-1:0] lut_sub_result;

    // Left shift by 1
    assign shifted_data = {din[WIDTH-2:0], 1'b0};

    // Use LUT-based subtractor to compute shifted_data - 0 (for demonstration, replace <<1 with subtractor)
    lut_subtractor_8b u_lut_subtractor (
        .a(shifted_data),
        .b(8'd0),
        .diff(lut_sub_result)
    );

    always @(posedge clk) begin
        dout <= lut_sub_result;
    end

endmodule

// ----------------------------------------------------------
// lut_subtractor_8b: 8-bit subtractor using lookup table (LUT)
// ----------------------------------------------------------
module lut_subtractor_8b (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff
);

    reg [7:0] lut_diff [0:65535];
    reg [7:0] diff_reg;

    wire [15:0] lut_addr;
    assign lut_addr = {a, b};

    initial begin : init_lut
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_diff[{i, j}] = i - j;
            end
        end
    end

    always @(*) begin
        diff_reg = lut_diff[lut_addr];
    end

    assign diff = diff_reg;

endmodule