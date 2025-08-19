//SystemVerilog
module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    reg [WIDTH-1:0] stage1_reg, stage2_reg, stage3_reg, stage4_reg;
    reg en_stage1, en_stage2, en_stage3, en_stage4;

    // Stage 1: Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 0;
            en_stage1 <= 0;
        end else begin
            stage1_reg <= d;
            en_stage1 <= en;
        end
    end

    // Stage 2: First pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_reg <= 0;
            en_stage2 <= 0;
        end else begin
            stage2_reg <= stage1_reg;
            en_stage2 <= en_stage1;
        end
    end

    // Stage 3: Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_reg <= 0;
            en_stage3 <= 0;
        end else begin
            stage3_reg <= stage2_reg;
            en_stage3 <= en_stage2;
        end
    end

    // Stage 4: Third pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_reg <= 0;
            en_stage4 <= 0;
        end else begin
            stage4_reg <= stage3_reg;
            en_stage4 <= en_stage3;
        end
    end

    // Stage 5: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
        end else if (en_stage4) begin
            q <= stage4_reg;
        end
    end

endmodule