//SystemVerilog
module Sync_AND(
    input clk,
    input reset_n,
    // Request-Acknowledge handshake signals
    input req,
    output reg ack,
    // Data signals
    input [7:0] signal_a, signal_b,
    output reg [7:0] reg_out
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    wire [7:0] and_result;
    wire processing_done;
    wire data_update_en;
    
    // 组合逻辑部分 - 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (req)
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                if (!req)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 组合逻辑部分 - 输出控制
    assign processing_done = (state == COMPLETE);
    assign data_update_en = (state == IDLE && req);
    
    // 组合逻辑部分 - 数据处理逻辑
    assign and_result = signal_a & signal_b;
    
    // 时序逻辑部分 - 状态寄存器
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 时序逻辑部分 - 输出寄存器
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ack <= 1'b0;
        end else begin
            ack <= processing_done;
        end
    end
    
    // 时序逻辑部分 - 数据输出寄存器
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_out <= 8'h00;
        end else if (data_update_en) begin
            reg_out <= and_result;
        end
    end
    
endmodule