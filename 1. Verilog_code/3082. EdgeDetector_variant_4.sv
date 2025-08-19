//SystemVerilog
module EdgeDetector #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input signal_in,
    output reg rising_edge,
    output reg falling_edge
);
    // 同步寄存器
    reg [1:0] sync_reg_stage1;
    // 边沿检测中间寄存器
    reg signal_stage1, signal_stage2;
    reg sync0_stage1, sync0_stage2;
    
    // 第一级流水线：同步和保存信号
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            sync_reg_stage1 <= 2'b00;
            signal_stage1 <= 1'b0;
            sync0_stage1 <= 1'b0;
        end else begin
            sync_reg_stage1 <= {sync_reg_stage1[0], signal_in};
            signal_stage1 <= signal_in;
            sync0_stage1 <= sync_reg_stage1[0];
        end
    end
    
    // 第二级流水线：准备比较信号
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            signal_stage2 <= 1'b0;
            sync0_stage2 <= 1'b0;
        end else begin
            signal_stage2 <= signal_stage1;
            sync0_stage2 <= sync0_stage1;
        end
    end
    
    // 第三级流水线：进行边沿检测计算和输出
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            rising_edge <= (sync0_stage2 & ~signal_stage2);
            falling_edge <= (~sync0_stage2 & signal_stage2);
        end
    end
endmodule