//SystemVerilog
module DigitalPLL #(parameter PHASE_BITS=10) (
    input clk, rst,
    input data_in,
    output reg data_sync
);
    reg [PHASE_BITS-1:0] phase_acc;
    reg [PHASE_BITS-1:0] phase_acc_next;
    wire [PHASE_BITS-1:0] increment;
    
    // 定义常量
    parameter [PHASE_BITS-1:0] FAST_INC = 100;
    parameter [PHASE_BITS-1:0] SLOW_INC = 90;
    
    // 选择增量值
    wire [PHASE_BITS-1:0] inc_sel;
    assign inc_sel = data_in ? FAST_INC : SLOW_INC;
    
    // 预计算下一个相位累加值
    always @(*) begin
        phase_acc_next = phase_acc + inc_sel;
    end
    
    // 主时序逻辑
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc <= 0;
            data_sync <= 0;
        end else begin
            phase_acc <= phase_acc_next;
            data_sync <= phase_acc_next[PHASE_BITS-1];
        end
    end
endmodule