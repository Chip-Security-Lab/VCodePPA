//SystemVerilog
module FunctionMultiplier(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] m,
    input [3:0] n,
    output reg [7:0] res,
    output reg res_valid
);

    // Pipeline registers
    reg [3:0] m_stage1, n_stage1;
    reg [7:0] mult_result_stage1;
    reg valid_stage1;
    
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // Stage 1: Input and multiplication with optimized ready logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_stage1 <= 4'b0;
            n_stage1 <= 4'b0;
            mult_result_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end
        else if (valid && ready) begin
            m_stage1 <= m;
            n_stage1 <= n;
            mult_result_stage1 <= m * n;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Result buffering with direct assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            result_stage2 <= mult_result_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage with optimized ready generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'b0;
            res_valid <= 1'b0;
            ready <= 1'b1;
        end
        else begin
            res <= result_stage2;
            res_valid <= valid_stage2;
            ready <= ~(valid_stage2 & ~res_valid);
        end
    end

endmodule