//SystemVerilog
module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    output reg detected
);
    // 状态寄存器
    reg [3:0] state;
    // 下一状态信号
    reg [3:0] next_state;
    // 检测匹配信号
    reg pattern_match;
    
    // 状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= 4'b0000;
        else 
            state <= next_state;
    end
    
    // 下一状态组合逻辑
    always @(*) begin
        next_state = {state[2:0], data_in};
    end
    
    // 模式匹配逻辑
    always @(*) begin
        pattern_match = (state == PATTERN);
    end
    
    // 输出逻辑寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            detected <= 1'b0;
        else
            detected <= pattern_match;
    end
endmodule