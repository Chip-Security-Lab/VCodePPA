//SystemVerilog
module async_iir_filter #(
    parameter DW = 14
)(
    input [DW-1:0] x_in,
    input [DW-1:0] y_prev,
    input [DW-1:0] a_coeff, b_coeff,
    input clk, rst_n,
    output reg [DW-1:0] y_out
);

    // Pipeline stage 1: Input registers and multiplication
    reg [DW-1:0] x_stage1, y_prev_stage1;
    reg [DW-1:0] a_coeff_stage1, b_coeff_stage1;
    reg [2*DW-1:0] mult_a_x_stage1;
    reg [2*DW-1:0] mult_b_y_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Scaling
    reg [DW-1:0] a_x_scaled_stage2;
    reg [DW-1:0] b_y_scaled_stage2;
    reg valid_stage2;

    // Pipeline stage 3: Addition
    reg [DW:0] sum_result_stage3;
    reg valid_stage3;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_stage1 <= 0;
            y_prev_stage1 <= 0;
            a_coeff_stage1 <= 0;
            b_coeff_stage1 <= 0;
            mult_a_x_stage1 <= 0;
            mult_b_y_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            x_stage1 <= x_in;
            y_prev_stage1 <= y_prev;
            a_coeff_stage1 <= a_coeff;
            b_coeff_stage1 <= b_coeff;
            mult_a_x_stage1 <= a_coeff * x_in;
            mult_b_y_stage1 <= b_coeff * y_prev;
            valid_stage1 <= 1;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_x_scaled_stage2 <= 0;
            b_y_scaled_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            a_x_scaled_stage2 <= mult_a_x_stage1[2*DW-1:DW];
            b_y_scaled_stage2 <= mult_b_y_stage1[2*DW-1:DW];
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_result_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            sum_result_stage3 <= a_x_scaled_stage2 + b_y_scaled_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= 0;
        end else if (valid_stage3) begin
            y_out <= sum_result_stage3[DW] ? {DW{1'b1}} : sum_result_stage3[DW-1:0];
        end
    end

endmodule