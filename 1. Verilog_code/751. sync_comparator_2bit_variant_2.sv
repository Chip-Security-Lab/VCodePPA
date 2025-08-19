//SystemVerilog
module sync_comparator_2bit_pipelined(
    input wire clk,
    input wire rst_n,
    input wire [1:0] data_a,
    input wire [1:0] data_b,
    output reg eq_out,
    output reg gt_out,
    output reg lt_out
);

    // Pipeline stage 1 registers
    reg [1:0] data_a_stage1;
    reg [1:0] data_b_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers
    reg eq_stage2;
    reg gt_stage2;
    reg lt_stage2;
    reg valid_stage2;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_stage1 <= 2'b0;
            data_b_stage1 <= 2'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_a_stage1 <= data_a;
            data_b_stage1 <= data_b;
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_stage2 <= 1'b0;
            gt_stage2 <= 1'b0;
            lt_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            eq_stage2 <= valid_stage1 ? (data_a_stage1 == data_b_stage1) : 1'b0;
            gt_stage2 <= valid_stage1 ? (data_a_stage1 > data_b_stage1) : 1'b0;
            lt_stage2 <= valid_stage1 ? (data_a_stage1 < data_b_stage1) : 1'b0;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_out <= 1'b0;
            gt_out <= 1'b0;
            lt_out <= 1'b0;
        end else begin
            eq_out <= valid_stage2 ? eq_stage2 : 1'b0;
            gt_out <= valid_stage2 ? gt_stage2 : 1'b0;
            lt_out <= valid_stage2 ? lt_stage2 : 1'b0;
        end
    end

endmodule