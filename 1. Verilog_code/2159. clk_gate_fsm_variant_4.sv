//SystemVerilog
module clk_gate_fsm (
    input wire clk, rst, en,
    output reg [1:0] state
);
    // 使用参数定义状态编码
    localparam S0 = 2'b00, 
               S1 = 2'b01, 
               S2 = 2'b10;
    
    // 流水线阶段寄存器
    reg [1:0] state_stage1;
    reg en_stage1;
    
    // 流水线控制信号
    reg valid_stage1;
    
    // 流水线第一级 - 保存当前状态和使能信号
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= S0;
            en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= state;
            en_stage1 <= en;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线第二级 - 计算下一个状态
    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end else if (valid_stage1) begin
            state <= en_stage1 ? (state_stage1 == S0 ? S1 :
                                 state_stage1 == S1 ? S2 : 
                                 S0) : state_stage1;
        end
    end
endmodule