//SystemVerilog
module lfsr_waveform(
    input            i_clk,
    input            i_rst,
    input            i_valid,    // 替代原来的i_enable，发送方表示数据请求有效
    output           o_ready,    // 新增信号，表示模块准备好接收新请求
    output [7:0]     o_random,   // 随机数输出
    output           o_valid     // 新增信号，表示输出数据有效
);
    reg [15:0] lfsr;
    reg        data_valid;     // 表示输出数据有效状态
    reg        ready_state;    // 模块准备状态
    
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    // 控制LFSR更新和握手状态
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr <= 16'hACE1;
            data_valid <= 1'b0;
            ready_state <= 1'b1;  // 复位后即可接收新请求
        end else begin
            if (i_valid && ready_state) begin
                // 有效请求且模块准备好时，更新LFSR
                lfsr <= {lfsr[14:0], feedback};
                data_valid <= 1'b1;  // 设置输出有效
                ready_state <= 1'b0;  // 处理中，暂不接收新请求
            end else if (data_valid) begin
                // 完成一次数据生成后，准备接收下一个请求
                data_valid <= 1'b0;
                ready_state <= 1'b1;
            end
        end
    end
    
    // 输出信号赋值
    assign o_random = lfsr[7:0];
    assign o_valid = data_valid;
    assign o_ready = ready_state;
    
endmodule