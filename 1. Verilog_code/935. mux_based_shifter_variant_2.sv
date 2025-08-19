//SystemVerilog
module mux_based_shifter (
    input clk,               // 时钟信号
    input rst_n,             // 复位信号，低电平有效
    
    // 输入接口 - Valid-Ready握手协议
    input [7:0] data_in,     // 输入数据
    input [2:0] shift_in,    // 位移控制信号
    input valid_in,          // 输入有效信号
    output reg ready_in,     // 输入就绪信号
    
    // 输出接口 - Valid-Ready握手协议
    output reg [7:0] data_out, // 输出数据
    output reg valid_out,      // 输出有效信号
    input ready_out           // 输出就绪信号
);

    // 内部信号
    wire [7:0] result;
    reg processing;
    
    // 原始位移逻辑
    wire [7:0] stage1 = shift_in[0] ? {data_in[6:0], data_in[7]} : data_in;
    wire [7:0] stage2 = shift_in[1] ? {stage1[5:0], stage1[7:6]} : stage1;
    assign result = shift_in[2] ? {stage2[3:0], stage2[7:4]} : stage2;
    
    // 握手控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;    // 复位后准备接收数据
            valid_out <= 1'b0;   // 复位后输出无效
            data_out <= 8'b0;    // 清零输出数据
            processing <= 1'b0;  // 未处理状态
        end
        else begin
            // 输入握手处理
            if (valid_in && ready_in) begin
                // 成功接收到输入
                ready_in <= 1'b0;     // 停止接收新数据
                valid_out <= 1'b1;    // 标记输出有效
                data_out <= result;   // 更新输出数据
                processing <= 1'b1;   // 进入处理状态
            end
            
            // 输出握手处理
            if (valid_out && ready_out) begin
                // 成功完成输出
                valid_out <= 1'b0;    // 清除输出有效信号
                ready_in <= 1'b1;     // 准备接收新数据
                processing <= 1'b0;   // 退出处理状态
            end
        end
    end
    
endmodule