//SystemVerilog
module rng_lcg_3_pipeline(
    input            clk,
    input            rst_n,
    input            en,
    output reg [7:0] rnd_out,
    output reg       valid_out
);
    parameter MULT = 8'd5;
    parameter INC  = 8'd1;

    // Stage 1 registers
    reg [7:0] rnd_stage1;
    reg       valid_stage1;

    // Stage 2 registers
    reg [15:0] mult_result_stage2;
    reg [7:0]  rnd_stage2;
    reg        valid_stage2;

    // Stage 3 registers
    reg [7:0] add_result_stage3;
    reg       valid_stage3;

    // Stage 1: Register previous output and en
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rnd_stage1   <= 8'd7;
        end else if (en) begin
            rnd_stage1   <= rnd_out;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else if (en) begin
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Multiply
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result_stage2 <= 16'd0;
        end else begin
            mult_result_stage2 <= rnd_stage1 * MULT;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rnd_stage2 <= 8'd0;
        end else begin
            rnd_stage2 <= rnd_stage1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Add
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add_result_stage3 <= 8'd7;
        end else begin
            add_result_stage3 <= mult_result_stage2[7:0] + INC;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rnd_out   <= 8'd7;
        end else if (valid_stage3) begin
            rnd_out   <= add_result_stage3;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else if (valid_stage3) begin
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule