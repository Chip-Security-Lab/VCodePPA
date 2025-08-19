//SystemVerilog
module park_miller_rng_pipeline (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire [31:0] rand_val_out,
    output wire        valid_out
);
    // Park-Miller constants
    parameter A = 16807;
    parameter M = 32'h7FFFFFFF; // 2^31 - 1
    parameter Q = 127773;       // M / A
    parameter R = 2836;         // M % A

    // Stage 1: Compute rand_val / Q, rand_val % Q (moved registers after combo logic)
    wire [31:0] rand_val_feedback;
    wire [31:0] stage1_seed_in;
    assign stage1_seed_in = start ? rand_val_feedback : rand_val_reg;

    wire [16:0] div_q_stage1_w;
    wire [16:0] mod_q_stage1_w;
    assign div_q_stage1_w = stage1_seed_in / Q;
    assign mod_q_stage1_w = stage1_seed_in % Q;

    reg [16:0] div_q_stage1;
    reg [16:0] mod_q_stage1;
    reg [31:0] rand_val_stage1;
    reg        valid_stage1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_q_stage1    <= 17'd0;
            mod_q_stage1    <= 17'd0;
            rand_val_stage1 <= 32'd1;
            valid_stage1    <= 1'b0;
        end else begin
            div_q_stage1    <= div_q_stage1_w;
            mod_q_stage1    <= mod_q_stage1_w;
            rand_val_stage1 <= stage1_seed_in;
            valid_stage1    <= start;
        end
    end

    // Stage 2: Compute A * (rand_val % Q)
    wire [31:0] mul_a_modq_stage2_w;
    assign mul_a_modq_stage2_w = A * mod_q_stage1;

    reg [31:0] mul_a_modq_stage2;
    reg [16:0] div_q_stage2;
    reg [31:0] rand_val_stage2;
    reg        valid_stage2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mul_a_modq_stage2 <= 32'd0;
            div_q_stage2      <= 17'd0;
            rand_val_stage2   <= 32'd1;
            valid_stage2      <= 1'b0;
        end else begin
            mul_a_modq_stage2 <= mul_a_modq_stage2_w;
            div_q_stage2      <= div_q_stage1;
            rand_val_stage2   <= rand_val_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3: Compute (M / Q) * (rand_val / Q)
    wire [31:0] mul_mq_divq_stage3_w;
    assign mul_mq_divq_stage3_w = (M / Q) * div_q_stage2;

    reg [31:0] mul_mq_divq_stage3;
    reg [31:0] mul_a_modq_stage3;
    reg        valid_stage3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mul_mq_divq_stage3 <= 32'd0;
            mul_a_modq_stage3  <= 32'd0;
            valid_stage3       <= 1'b0;
        end else begin
            mul_mq_divq_stage3 <= mul_mq_divq_stage3_w;
            mul_a_modq_stage3  <= mul_a_modq_stage2;
            valid_stage3       <= valid_stage2;
        end
    end

    // Stage 4: Subtract and check result
    wire signed [32:0] temp_stage4_w;
    assign temp_stage4_w = $signed({1'b0, mul_a_modq_stage3}) - $signed({1'b0, mul_mq_divq_stage3});

    reg signed [32:0] temp_stage4;
    reg        valid_stage4;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temp_stage4  <= 33'd1;
            valid_stage4 <= 1'b0;
        end else begin
            temp_stage4  <= temp_stage4_w;
            valid_stage4 <= valid_stage3;
        end
    end

    // Stage 5: Final output selection
    reg [31:0] rand_val_stage5;
    reg        valid_stage5;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_val_stage5 <= 32'd1;
            valid_stage5    <= 1'b0;
        end else if (valid_stage4) begin
            if (temp_stage4 <= 0)
                rand_val_stage5 <= temp_stage4[31:0] + M;
            else
                rand_val_stage5 <= temp_stage4[31:0];
            valid_stage5 <= 1'b1;
        end else begin
            valid_stage5 <= 1'b0;
        end
    end

    // Feedback and output logic
    reg [31:0] rand_val_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_val_reg <= 32'd1;
        end else if (valid_stage5) begin
            rand_val_reg <= rand_val_stage5;
        end
    end

    assign rand_val_feedback = rand_val_reg;
    assign rand_val_out = rand_val_reg;
    assign valid_out    = valid_stage5;

endmodule