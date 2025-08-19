//SystemVerilog
module ring_counter_req_ack (
    input clk, rst_n,
    input req,           // Request signal (replacing valid)
    output reg ack,      // Acknowledge signal (replacing ready)
    output [3:0] cnt
);
    // 内部寄存器信号
    reg internal_bit;
    reg [1:0] handshake_state;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam REQ_RECEIVED = 2'b01;
    localparam DATA_VALID = 2'b10;
    
    // 使用组合逻辑直接构建输出
    assign cnt = {internal_bit, 1'b0, 1'b0, ~internal_bit};
    
    // 握手协议状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handshake_state <= IDLE;
            ack <= 1'b0;
            internal_bit <= 1'b0; // 重置状态对应原始的4'b0001
        end
        else begin
            case (handshake_state)
                IDLE: begin
                    ack <= 1'b0;
                    if (req) begin
                        handshake_state <= REQ_RECEIVED;
                    end
                end
                
                REQ_RECEIVED: begin
                    internal_bit <= ~internal_bit; // 更新计数器值
                    ack <= 1'b1; // 发送应答信号
                    handshake_state <= DATA_VALID;
                end
                
                DATA_VALID: begin
                    if (!req) begin
                        ack <= 1'b0;
                        handshake_state <= IDLE;
                    end
                end
                
                default: begin
                    handshake_state <= IDLE;
                end
            endcase
        end
    end
endmodule