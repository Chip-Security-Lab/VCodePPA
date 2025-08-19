//SystemVerilog
// Top-level module: Multi-phase Clock Generator (Pipelined)
module multi_phase_clk_gen(
    input  wire clk_in,
    input  wire reset,
    output wire clk_0,    // 0 degrees
    output wire clk_90,   // 90 degrees
    output wire clk_180,  // 180 degrees
    output wire clk_270   // 270 degrees
);

    // Internal pipeline signals
    wire [1:0] phase_count_stage1;
    wire [1:0] phase_count_stage2;
    wire [1:0] phase_count_stage3;

    // Phase Counter Submodule Instance (Pipelined)
    phase_counter_pipelined #(
        .WIDTH(2)
    ) u_phase_counter_pipelined (
        .clk                (clk_in),
        .reset              (reset),
        .count_out_stage1   (phase_count_stage1),
        .count_out_stage2   (phase_count_stage2),
        .count_out_stage3   (phase_count_stage3)
    );

    // Phase Decoder Submodule Instance (Pipelined)
    phase_decoder_pipelined u_phase_decoder_pipelined (
        .clk                (clk_in),
        .reset              (reset),
        .phase_count_in     (phase_count_stage3),
        .clk_0              (clk_0),
        .clk_90             (clk_90),
        .clk_180            (clk_180),
        .clk_270            (clk_270)
    );

endmodule

// Phase Counter Submodule (Pipelined)
// Generates a modulo-4 counter with two pipeline stages
module phase_counter_pipelined #(
    parameter WIDTH = 2
)(
    input  wire             clk,
    input  wire             reset,
    output reg  [WIDTH-1:0] count_out_stage1,
    output reg  [WIDTH-1:0] count_out_stage2,
    output reg  [WIDTH-1:0] count_out_stage3
);
    reg  [WIDTH-1:0] count_reg_stage0;
    wire [WIDTH-1:0] count_next_stage0;

    // Stage 0: Counter logic (split addition into two stages)
    assign count_next_stage0 = count_reg_stage0 + {{(WIDTH-1){1'b0}}, 1'b1};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_reg_stage0     <= {WIDTH{1'b0}};
            count_out_stage1     <= {WIDTH{1'b0}};
            count_out_stage2     <= {WIDTH{1'b0}};
            count_out_stage3     <= {WIDTH{1'b0}};
        end else begin
            count_reg_stage0     <= count_next_stage0;        // Counter increment (Stage 0)
            count_out_stage1     <= count_reg_stage0;         // Pipeline Stage 1
            count_out_stage2     <= count_out_stage1;         // Pipeline Stage 2
            count_out_stage3     <= count_out_stage2;         // Pipeline Stage 3 (output for decoder)
        end
    end
endmodule

// Phase Decoder Submodule (Pipelined)
// Decodes the counter value into four clock phase signals with two pipeline stages
module phase_decoder_pipelined(
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  phase_count_in,
    output reg         clk_0,
    output reg         clk_90,
    output reg         clk_180,
    output reg         clk_270
);
    // Pipeline registers for decoder outputs
    reg clk_0_stage1, clk_90_stage1, clk_180_stage1, clk_270_stage1;
    reg clk_0_stage2, clk_90_stage2, clk_180_stage2, clk_270_stage2;

    // Stage 1: Decode phase_count_in (combinational to registered)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_0_stage1   <= 1'b0;
            clk_90_stage1  <= 1'b0;
            clk_180_stage1 <= 1'b0;
            clk_270_stage1 <= 1'b0;
        end else begin
            clk_0_stage1   <= (phase_count_in == 2'b00);
            clk_90_stage1  <= (phase_count_in == 2'b01);
            clk_180_stage1 <= (phase_count_in == 2'b10);
            clk_270_stage1 <= (phase_count_in == 2'b11);
        end
    end

    // Stage 2: Pipeline register (for output timing balancing)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_0_stage2   <= 1'b0;
            clk_90_stage2  <= 1'b0;
            clk_180_stage2 <= 1'b0;
            clk_270_stage2 <= 1'b0;
        end else begin
            clk_0_stage2   <= clk_0_stage1;
            clk_90_stage2  <= clk_90_stage1;
            clk_180_stage2 <= clk_180_stage1;
            clk_270_stage2 <= clk_270_stage1;
        end
    end

    // Stage 3: Output assignment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_0   <= 1'b0;
            clk_90  <= 1'b0;
            clk_180 <= 1'b0;
            clk_270 <= 1'b0;
        end else begin
            clk_0   <= clk_0_stage2;
            clk_90  <= clk_90_stage2;
            clk_180 <= clk_180_stage2;
            clk_270 <= clk_270_stage2;
        end
    end
endmodule