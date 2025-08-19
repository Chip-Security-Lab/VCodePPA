//SystemVerilog
module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

    // 寄存器声明
    reg [W-1:0] delay_line [DELAY-1:0];
    reg [W-1:0] delayed_sample;
    
    // 组合逻辑部分
    wire [W-1:0] next_dout;
    assign next_dout = din - delayed_sample;
    
    // 时序逻辑部分 - 延迟线更新
    always @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < DELAY; i = i + 1)
                delay_line[i] <= 0;
        end else if (enable) begin
            delay_line[0] <= din;
            for (int i = 1; i < DELAY; i = i + 1)
                delay_line[i] <= delay_line[i-1];
        end
    end
    
    // 时序逻辑部分 - 延迟采样和输出
    always @(posedge clk) begin
        if (!rst_n) begin
            delayed_sample <= 0;
            dout <= 0;
        end else if (enable) begin
            delayed_sample <= delay_line[DELAY-1];
            dout <= next_dout;
        end
    end
endmodule