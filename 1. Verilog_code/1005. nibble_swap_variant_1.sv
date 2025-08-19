//SystemVerilog
// Top-level module: nibble_swap_pipeline_top
// Structured pipeline for nibble swapping of a 16-bit input.
// Data path is reorganized into clear pipeline stages with explicit pipeline registers.

module nibble_swap_pipeline_top(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire        swap_en,
    output wire [15:0] data_out
);

    // Stage 1: Input register
    reg  [15:0] data_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_stage1 <= 16'd0;
        else
            data_in_stage1 <= data_in;
    end

    // Stage 2: Nibble extraction
    wire [3:0] nibble_stage2_3, nibble_stage2_2, nibble_stage2_1, nibble_stage2_0;
    nibble_extractor u_nibble_extractor (
        .data_in    (data_in_stage1),
        .nibble3    (nibble_stage2_3),
        .nibble2    (nibble_stage2_2),
        .nibble1    (nibble_stage2_1),
        .nibble0    (nibble_stage2_0)
    );

    // Pipeline registers for nibbles (Stage 2 -> Stage 3)
    reg [3:0] nibble_stage3_3, nibble_stage3_2, nibble_stage3_1, nibble_stage3_0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nibble_stage3_3 <= 4'd0;
            nibble_stage3_2 <= 4'd0;
            nibble_stage3_1 <= 4'd0;
            nibble_stage3_0 <= 4'd0;
        end else begin
            nibble_stage3_3 <= nibble_stage2_3;
            nibble_stage3_2 <= nibble_stage2_2;
            nibble_stage3_1 <= nibble_stage2_1;
            nibble_stage3_0 <= nibble_stage2_0;
        end
    end

    // Pipeline register for swap_en and original data (to align control/data)
    reg swap_en_stage3;
    reg [15:0] data_in_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swap_en_stage3   <= 1'b0;
            data_in_stage3   <= 16'd0;
        end else begin
            swap_en_stage3   <= swap_en;
            data_in_stage3   <= data_in_stage1;
        end
    end

    // Stage 3: Nibble swapping
    wire [15:0] swapped_data_stage4;
    nibble_swapper u_nibble_swapper (
        .nibble3    (nibble_stage3_3),
        .nibble2    (nibble_stage3_2),
        .nibble1    (nibble_stage3_1),
        .nibble0    (nibble_stage3_0),
        .swapped    (swapped_data_stage4)
    );

    // Pipeline register for swapped data (Stage 4)
    reg [15:0] swapped_data_stage5;
    reg [15:0] orig_data_stage5;
    reg        swap_en_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swapped_data_stage5 <= 16'd0;
            orig_data_stage5    <= 16'd0;
            swap_en_stage5      <= 1'b0;
        end else begin
            swapped_data_stage5 <= swapped_data_stage4;
            orig_data_stage5    <= data_in_stage3;
            swap_en_stage5      <= swap_en_stage3;
        end
    end

    // Stage 5: Output selection
    output_mux u_output_mux (
        .orig_data      (orig_data_stage5),
        .swapped_data   (swapped_data_stage5),
        .swap_en        (swap_en_stage5),
        .data_out       (data_out)
    );

endmodule

//------------------------------------------------------------------------------
// nibble_extractor
// Function: Extracts four nibbles from a 16-bit input
//------------------------------------------------------------------------------

module nibble_extractor(
    input  wire [15:0] data_in,
    output wire [3:0]  nibble3,
    output wire [3:0]  nibble2,
    output wire [3:0]  nibble1,
    output wire [3:0]  nibble0
);
    assign nibble3 = data_in[15:12];
    assign nibble2 = data_in[11:8];
    assign nibble1 = data_in[7:4];
    assign nibble0 = data_in[3:0];
endmodule

//------------------------------------------------------------------------------
// nibble_swapper
// Function: Rearranges four nibbles from [nibble3|nibble2|nibble1|nibble0]
//           to [nibble0|nibble1|nibble2|nibble3]
//------------------------------------------------------------------------------

module nibble_swapper(
    input  wire [3:0] nibble3,
    input  wire [3:0] nibble2,
    input  wire [3:0] nibble1,
    input  wire [3:0] nibble0,
    output wire [15:0] swapped
);
    assign swapped = {nibble0, nibble1, nibble2, nibble3};
endmodule

//------------------------------------------------------------------------------
// output_mux
// Function: Selects either the original or swapped data based on swap_en
//------------------------------------------------------------------------------

module output_mux(
    input  wire [15:0] orig_data,
    input  wire [15:0] swapped_data,
    input  wire        swap_en,
    output wire [15:0] data_out
);
    assign data_out = swap_en ? swapped_data : orig_data;
endmodule