module DigitalPLL #(parameter PHASE_BITS=10) (
    input clk, rst,
    input data_in,
    output reg data_sync
);
    reg [PHASE_BITS-1:0] phase_acc;
    wire [PHASE_BITS-1:0] increment;
    
    // 定义常量
    parameter [PHASE_BITS-1:0] FAST_INC = 100;
    parameter [PHASE_BITS-1:0] SLOW_INC = 90;
    
    assign increment = data_in ? FAST_INC : SLOW_INC;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc <= 0;
            data_sync <= 0;
        end else begin
            phase_acc <= phase_acc + increment;
            data_sync <= phase_acc[PHASE_BITS-1];
        end
    end
endmodule