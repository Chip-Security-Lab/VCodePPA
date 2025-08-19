//SystemVerilog
module DigitalPLL #(parameter PHASE_BITS=10) (
    input clk, rst,
    input data_in,
    output reg data_sync
);
    reg [PHASE_BITS-1:0] phase_acc;
    reg [PHASE_BITS-1:0] pipeline_phase;
    wire [PHASE_BITS-1:0] increment;
    reg data_in_reg;
    reg [PHASE_BITS-1:0] phase_acc_next;
    reg [PHASE_BITS-1:0] pipeline_phase_next;
    reg data_sync_next;
    
    parameter [PHASE_BITS-1:0] FAST_INC = 100;
    parameter [PHASE_BITS-1:0] SLOW_INC = 90;
    
    // 组合逻辑计算下一状态
    assign increment = data_in ? FAST_INC : SLOW_INC;
    assign phase_acc_next = phase_acc + increment;
    assign pipeline_phase_next = phase_acc_next;
    assign data_sync_next = pipeline_phase_next[PHASE_BITS-1];
    
    // 时序逻辑更新状态
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc <= 0;
            pipeline_phase <= 0;
            data_sync <= 0;
            data_in_reg <= 0;
        end else begin
            phase_acc <= phase_acc_next;
            pipeline_phase <= pipeline_phase_next;
            data_sync <= data_sync_next;
            data_in_reg <= data_in;
        end
    end
endmodule