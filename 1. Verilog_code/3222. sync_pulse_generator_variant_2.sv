//SystemVerilog
module sync_pulse_generator(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] period_i,
    input [15:0] width_i,
    output reg pulse_o
);
    reg [15:0] counter;
    reg [15:0] counter_buf1, counter_buf2; // 添加counter的缓冲寄存器
    
    // 定义控制状态
    reg [1:0] state;
    reg [1:0] state_buf1, state_buf2; // 添加state的缓冲寄存器
    
    parameter RESET = 2'b00;
    parameter ENABLED = 2'b01;
    parameter DISABLED = 2'b10;
    
    // 状态控制逻辑 - 拆分为单独的always块以减少关键路径
    always @(posedge clk_i) begin
        // 确定当前状态
        case ({rst_i, en_i})
            2'b10, 2'b11: state <= RESET;    // 复位状态优先
            2'b01:        state <= ENABLED;  // 使能状态
            2'b00:        state <= DISABLED; // 禁用状态
        endcase
    end
    
    // 增加state的缓冲寄存器
    always @(posedge clk_i) begin
        state_buf1 <= state;
        state_buf2 <= state_buf1;
    end
    
    // 计数器逻辑 - 拆分为单独的always块
    always @(posedge clk_i) begin
        if (state_buf1 == RESET) begin
            counter <= 16'd0;
        end
        else if (state_buf1 == ENABLED) begin
            // 计数器逻辑
            if (counter >= period_i-1)
                counter <= 16'd0;
            else
                counter <= counter + 16'd1;
        end
    end
    
    // 增加counter的缓冲寄存器
    always @(posedge clk_i) begin
        counter_buf1 <= counter;
        counter_buf2 <= counter_buf1;
    end
    
    // 脉冲输出逻辑 - 使用缓冲后的信号
    always @(posedge clk_i) begin
        if (state_buf2 == RESET) begin
            pulse_o <= 1'b0;
        end
        else if (state_buf2 == ENABLED) begin
            // 脉冲输出逻辑
            pulse_o <= (counter_buf2 < width_i) ? 1'b1 : 1'b0;
        end
    end
endmodule