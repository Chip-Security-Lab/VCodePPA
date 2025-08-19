//SystemVerilog
module fsm_parity_check (
    input clk, rst_n,
    input data_valid,
    input [7:0] data,
    output reg parity
);
    // 使用参数而非typedef enum
    parameter IDLE = 1'b0;
    parameter CALC = 1'b1;
    
    reg state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            parity <= 0;
        end else if (state == IDLE && data_valid) begin
            parity <= ^data;
            state <= CALC;
        end else if (state == CALC) begin
            state <= IDLE;
        end else if (state != IDLE) begin
            // 包含default情况
            state <= IDLE;
        end
    end
endmodule