//SystemVerilog
module fsm_parity_check (
    input clk, rst_n,
    input req,          // 原data_valid信号，现在是请求信号
    input [7:0] data,
    output reg parity,
    output reg ack      // 新增应答信号
);
    // 使用参数而非typedef enum
    parameter IDLE = 2'b00;
    parameter CALC = 2'b01;
    parameter WAIT_REQ_LOW = 2'b10;
    
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            parity <= 0;
            ack <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        parity <= ^data;
                        ack <= 1'b1;
                        state <= CALC;
                    end else begin
                        ack <= 1'b0;
                    end
                end
                
                CALC: begin
                    if (!req) begin
                        ack <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                WAIT_REQ_LOW: begin
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                    ack <= 1'b0;
                end
            endcase
        end
    end
endmodule