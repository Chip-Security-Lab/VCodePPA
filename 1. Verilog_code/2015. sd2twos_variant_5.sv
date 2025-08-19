//SystemVerilog

module sd2twos #(parameter W=8) (
    input  wire [W-1:0] sd,
    output wire [W:0]   twos
);
    // Stage 1: Input Extension and Operand Preparation
    wire [W:0] sd_ext_stage1;
    wire [W:0] add_operand_stage1;
    reg  [W:0] sd_ext_stage2;
    reg  [W:0] add_operand_stage2;

    // Pipeline Register Stage 1
    assign sd_ext_stage1      = {1'b0, sd};
    assign add_operand_stage1 = {sd[W-1], {W-1{1'b0}}, 1'b0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sd_ext_stage2      <= {W+1{1'b0}};
            add_operand_stage2 <= {W+1{1'b0}};
        end else begin
            sd_ext_stage2      <= sd_ext_stage1;
            add_operand_stage2 <= add_operand_stage1;
        end
    end

    // Stage 2: Han-Carlson Adder Pipeline
    wire [W:0] sum_stage2;
    reg  [W:0] sum_stage3;

    han_carlson_adder_9_pipeline hc_adder_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .a(sd_ext_stage2),
        .b(add_operand_stage2),
        .sum(sum_stage2)
    );

    // Pipeline Register Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage3 <= {W+1{1'b0}};
        end else begin
            sum_stage3 <= sum_stage2;
        end
    end

    // Output Assignment
    assign twos = sum_stage3;

endmodule

// Pipelined Han-Carlson Adder for 9-bit input
module han_carlson_adder_9_pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [8:0]  a,
    input  wire [8:0]  b,
    output wire [8:0]  sum
);
    // Stage 1: Generate and Propagate
    reg [8:0] g_stage1, p_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage1 <= 9'b0;
            p_stage1 <= 9'b0;
        end else begin
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
        end
    end

    // Stage 2: Black cells for 1 distance
    reg [8:0] g_stage2, p_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage2 <= 9'b0;
            p_stage2 <= 9'b0;
        end else begin
            g_stage2[0] <= g_stage1[0];
            p_stage2[0] <= p_stage1[0];
            g_stage2[1] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
            p_stage2[1] <= p_stage1[1] & p_stage1[0];
            g_stage2[2] <= g_stage1[2] | (p_stage1[2] & g_stage1[1]);
            p_stage2[2] <= p_stage1[2] & p_stage1[1];
            g_stage2[3] <= g_stage1[3] | (p_stage1[3] & g_stage1[2]);
            p_stage2[3] <= p_stage1[3] & p_stage1[2];
            g_stage2[4] <= g_stage1[4] | (p_stage1[4] & g_stage1[3]);
            p_stage2[4] <= p_stage1[4] & p_stage1[3];
            g_stage2[5] <= g_stage1[5] | (p_stage1[5] & g_stage1[4]);
            p_stage2[5] <= p_stage1[5] & p_stage1[4];
            g_stage2[6] <= g_stage1[6] | (p_stage1[6] & g_stage1[5]);
            p_stage2[6] <= p_stage1[6] & p_stage1[5];
            g_stage2[7] <= g_stage1[7] | (p_stage1[7] & g_stage1[6]);
            p_stage2[7] <= p_stage1[7] & p_stage1[6];
            g_stage2[8] <= g_stage1[8] | (p_stage1[8] & g_stage1[7]);
            p_stage2[8] <= p_stage1[8] & p_stage1[7];
        end
    end

    // Stage 3: Black cells for 2 distance
    reg [8:0] g_stage3, p_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage3 <= 9'b0;
            p_stage3 <= 9'b0;
        end else begin
            g_stage3[0] <= g_stage2[0];
            p_stage3[0] <= p_stage2[0];
            g_stage3[1] <= g_stage2[1];
            p_stage3[1] <= p_stage2[1];
            g_stage3[2] <= g_stage2[2] | (p_stage2[2] & g_stage2[0]);
            p_stage3[2] <= p_stage2[2] & p_stage2[0];
            g_stage3[3] <= g_stage2[3] | (p_stage2[3] & g_stage2[1]);
            p_stage3[3] <= p_stage2[3] & p_stage2[1];
            g_stage3[4] <= g_stage2[4] | (p_stage2[4] & g_stage2[2]);
            p_stage3[4] <= p_stage2[4] & p_stage2[2];
            g_stage3[5] <= g_stage2[5] | (p_stage2[5] & g_stage2[3]);
            p_stage3[5] <= p_stage2[5] & p_stage2[3];
            g_stage3[6] <= g_stage2[6] | (p_stage2[6] & g_stage2[4]);
            p_stage3[6] <= p_stage2[6] & p_stage2[4];
            g_stage3[7] <= g_stage2[7] | (p_stage2[7] & g_stage2[5]);
            p_stage3[7] <= p_stage2[7] & p_stage2[5];
            g_stage3[8] <= g_stage2[8] | (p_stage2[8] & g_stage2[6]);
            p_stage3[8] <= p_stage2[8] & p_stage2[6];
        end
    end

    // Stage 4: Black cells for 4 distance
    reg [8:0] g_stage4, p_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage4 <= 9'b0;
            p_stage4 <= 9'b0;
        end else begin
            g_stage4[0] <= g_stage3[0];
            p_stage4[0] <= p_stage3[0];
            g_stage4[1] <= g_stage3[1];
            p_stage4[1] <= p_stage3[1];
            g_stage4[2] <= g_stage3[2];
            p_stage4[2] <= p_stage3[2];
            g_stage4[3] <= g_stage3[3];
            p_stage4[3] <= p_stage3[3];
            g_stage4[4] <= g_stage3[4] | (p_stage3[4] & g_stage3[0]);
            p_stage4[4] <= p_stage3[4] & p_stage3[0];
            g_stage4[5] <= g_stage3[5] | (p_stage3[5] & g_stage3[1]);
            p_stage4[5] <= p_stage3[5] & p_stage3[1];
            g_stage4[6] <= g_stage3[6] | (p_stage3[6] & g_stage3[2]);
            p_stage4[6] <= p_stage3[6] & p_stage3[2];
            g_stage4[7] <= g_stage3[7] | (p_stage3[7] & g_stage3[3]);
            p_stage4[7] <= p_stage3[7] & p_stage3[3];
            g_stage4[8] <= g_stage3[8] | (p_stage3[8] & g_stage3[4]);
            p_stage4[8] <= p_stage3[8] & p_stage3[4];
        end
    end

    // Stage 5: Black cells for 8 distance (only for MSB)
    reg [8:0] g_stage5, p_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage5 <= 9'b0;
            p_stage5 <= 9'b0;
        end else begin
            g_stage5[0] <= g_stage4[0];
            p_stage5[0] <= p_stage4[0];
            g_stage5[1] <= g_stage4[1];
            p_stage5[1] <= p_stage4[1];
            g_stage5[2] <= g_stage4[2];
            p_stage5[2] <= p_stage4[2];
            g_stage5[3] <= g_stage4[3];
            p_stage5[3] <= p_stage4[3];
            g_stage5[4] <= g_stage4[4];
            p_stage5[4] <= p_stage4[4];
            g_stage5[5] <= g_stage4[5];
            p_stage5[5] <= p_stage4[5];
            g_stage5[6] <= g_stage4[6];
            p_stage5[6] <= p_stage4[6];
            g_stage5[7] <= g_stage4[7];
            p_stage5[7] <= p_stage4[7];
            g_stage5[8] <= g_stage4[8] | (p_stage4[8] & g_stage4[0]);
            p_stage5[8] <= p_stage4[8] & p_stage4[0];
        end
    end

    // Stage 6: Carry and sum computation
    reg [8:0] carry_stage6, p_stage6;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage6 <= 9'b0;
            p_stage6     <= 9'b0;
        end else begin
            carry_stage6[0] <= 1'b0;
            carry_stage6[1] <= g_stage1[0];
            carry_stage6[2] <= g_stage2[1];
            carry_stage6[3] <= g_stage3[2];
            carry_stage6[4] <= g_stage4[3];
            carry_stage6[5] <= g_stage4[4];
            carry_stage6[6] <= g_stage4[5];
            carry_stage6[7] <= g_stage4[6];
            carry_stage6[8] <= g_stage5[7];
            p_stage6        <= p_stage5;
        end
    end

    assign sum = p_stage6 ^ carry_stage6;

endmodule