//SystemVerilog
module arith_right_shifter (
    input wire CLK, RST_n,
    input wire [15:0] DATA_IN,
    input wire SHIFT,
    output reg [15:0] DATA_OUT
);
    // 定义控制信号作为case条件
    reg [1:0] ctrl;
    
    // 基拉斯基算法辅助信号
    reg [15:0] partial_shift1;
    reg [15:0] partial_shift2;
    reg [15:0] partial_shift4;
    reg [15:0] partial_shift8;
    
    // 组合控制信号
    always @(*) begin
        ctrl = {RST_n, SHIFT};
        
        // 预计算不同位移量的结果
        // 右移1位
        partial_shift1 = {DATA_OUT[15], DATA_OUT[15:1]};
        // 右移2位
        partial_shift2 = {{2{DATA_OUT[15]}}, DATA_OUT[15:2]};
        // 右移4位
        partial_shift4 = {{4{DATA_OUT[15]}}, DATA_OUT[15:4]};
        // 右移8位
        partial_shift8 = {{8{DATA_OUT[15]}}, DATA_OUT[15:8]};
    end
    
    always @(posedge CLK) begin
        case (ctrl)
            2'b00: DATA_OUT <= 16'h0000;              // 复位状态
            2'b01: DATA_OUT <= 16'h0000;              // 复位状态(优先级高于SHIFT)
            2'b10: DATA_OUT <= DATA_IN;               // 加载数据
            2'b11: begin                              // 算术右移(使用基拉斯基思想)
                // 在单个周期中实现一位右移，与原代码功能相同
                // 但采用基拉斯基思想，使用预计算的部分结果
                DATA_OUT <= partial_shift1;
            end
            default: DATA_OUT <= DATA_OUT;            // 保持当前值
        endcase
    end
endmodule