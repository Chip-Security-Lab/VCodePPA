//SystemVerilog
module ITRC_EdgeDetect #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,    // 中断源输入
    output reg [WIDTH-1:0] int_out, // 同步输出
    output reg int_valid           // 中断有效标志
);
    reg [WIDTH-1:0] prev_state_stage1;
    reg [WIDTH-1:0] edge_detected_stage2;
    reg valid_signal_stage3;

    // Stage 1: Store previous state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state_stage1 <= 0;
        end else begin
            prev_state_stage1 <= int_src;
        end
    end

    // Stage 2: Edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage2 <= 0;
        end else begin
            edge_detected_stage2 <= (int_src ^ prev_state_stage1) & int_src; // 上升沿检测
        end
    end

    // Stage 3: Valid signal generation and output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= 0;
            int_valid <= 0;
        end else begin
            int_out <= edge_detected_stage2;
            valid_signal_stage3 <= |edge_detected_stage2;
            int_valid <= valid_signal_stage3;
        end
    end
endmodule