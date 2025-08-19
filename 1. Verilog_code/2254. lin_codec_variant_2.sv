//SystemVerilog
module lin_codec (
    input clk, break_detect,
    input [7:0] pid,
    output reg tx
);
    reg [12:0] shift_reg;
    reg break_detect_delayed;
    reg load_shifter;
    
    // 组合逻辑直接处理输入信号，去除输入寄存
    wire break_detect_immediate = break_detect;
    wire [7:0] pid_immediate = pid;
    
    // 控制逻辑模块 - 立即响应break信号
    always @(posedge clk) begin
        break_detect_delayed <= break_detect_immediate;
        load_shifter <= break_detect_immediate;
    end
    
    // 移位寄存器控制模块 - 直接使用未寄存的输入
    always @(posedge clk) begin
        if(break_detect_immediate) begin
            // 直接使用输入PID，减少一级寄存延迟
            shift_reg <= {pid_immediate, 4'h0, 1'b0};
        end
        else begin
            // 正常移位操作
            shift_reg <= {shift_reg[11:0], 1'b1};
        end
    end
    
    // 输出控制模块
    always @(posedge clk) begin
        if(break_detect_delayed) begin
            // 当检测到break时，输出低电平
            tx <= 1'b0;
        end
        else begin
            // 正常操作时，输出移位寄存器的最高位
            tx <= shift_reg[12];
        end
    end
endmodule