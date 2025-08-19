//SystemVerilog
module signed_multiply_subtract (
    input wire clk,
    input wire rst_n,
    input wire valid,
    output wire ready,
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output reg signed [15:0] result,
    output reg result_valid
);

    // Pipeline stage signals
    reg signed [7:0] a_stage1, b_stage1, c_stage1;
    reg signed [15:0] mult_result_stage2;
    reg signed [15:0] final_result_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;

    // Ready signal generation
    assign ready = !valid_stage1;

    // Stage 1: Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'd0;
            b_stage1 <= 8'd0;
            c_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else if (ready) begin
            a_stage1 <= a;
            b_stage1 <= b;
            c_stage1 <= c;
            valid_stage1 <= valid;
        end
    end

    // Stage 2: Multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result_stage2 <= 16'd0;
            valid_stage2 <= 1'b0;
        end else begin
            mult_result_stage2 <= a_stage1 * b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result_stage3 <= 16'd0;
            valid_stage3 <= 1'b0;
        end else begin
            final_result_stage3 <= mult_result_stage2 - c_stage1;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'd0;
            result_valid <= 1'b0;
        end else begin
            result <= final_result_stage3;
            result_valid <= valid_stage3;
        end
    end

endmodule