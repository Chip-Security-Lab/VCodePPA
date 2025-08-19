//SystemVerilog
module ITRC_EdgeDetect_Pipeline #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,    // 中断源输入
    output reg [WIDTH-1:0] int_out, // 同步输出
    output reg int_valid           // 中断有效标志
);

    // Pipeline registers
    reg [WIDTH-1:0] int_src_stage1;
    reg [WIDTH-1:0] prev_state_stage1;
    reg [WIDTH-1:0] int_out_stage2;
    reg int_valid_stage2;

    // Stage 1: Capture input and previous state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= 0;
            prev_state_stage1 <= 0;
        end else begin
            int_src_stage1 <= int_src;
            prev_state_stage1 <= int_src_stage1;
        end
    end

    // Stage 2: Compute edge detection using conditional sum subtraction algorithm
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out_stage2 <= 0;
            int_valid_stage2 <= 0;
        end else begin
            // Conditional sum subtraction implementation
            int_out_stage2 <= int_src_stage1 - prev_state_stage1; // 直接替换为减法
            int_valid_stage2 <= |int_out_stage2;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= 0;
            int_valid <= 0;
        end else begin
            int_out <= int_out_stage2;
            int_valid <= int_valid_stage2;
        end
    end

endmodule