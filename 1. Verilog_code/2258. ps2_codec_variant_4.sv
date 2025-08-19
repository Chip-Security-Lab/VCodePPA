//SystemVerilog - IEEE 1364-2005
module ps2_codec (
    input clk_ps2, data,
    output reg [7:0] keycode,
    output reg parity_ok
);
    reg [10:0] shift;
    reg data_reg;
    reg shift_complete;
    reg [7:0] keycode_next;
    reg parity_next;
    
    // 数据输入注册块 - 处理输入数据采样
    always @(negedge clk_ps2) begin
        data_reg <= data;
    end
    
    // 移位寄存器块 - 处理PS2数据帧的移位操作
    always @(negedge clk_ps2) begin
        shift <= {data_reg, shift[10:1]};
    end
    
    // 数据解析与状态检测块 - 解析PS2数据并执行校验
    always @(negedge clk_ps2) begin
        shift_complete <= shift[0];
        keycode_next <= shift[8:1];
        parity_next <= (^shift[8:1] == shift[9]);
    end
    
    // 输出控制块 - 根据解析结果更新输出信号
    always @(negedge clk_ps2) begin
        if(shift_complete) begin
            parity_ok <= parity_next;
            keycode <= keycode_next;
        end
    end
endmodule