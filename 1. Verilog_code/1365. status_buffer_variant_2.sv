//SystemVerilog
module status_buffer (
    input wire clk,
    input wire rst_n,        // 添加复位信号以符合标准设计实践
    input wire [7:0] status_in,
    input wire valid,        // 替代原先的update信号
    output reg ready,        // 替代原先的ack信号
    input wire clear,
    output reg [7:0] status_out
);
    // 内部状态机状态
    localparam IDLE = 2'd0,
               PROCESS = 2'd1,
               COMPLETE = 2'd2;
    
    reg [1:0] state, next_state;
    reg [7:0] status_reg;
    
    // 状态机 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            status_out <= 8'b0;
        end else begin
            state <= next_state;
            
            if (clear)
                status_out <= 8'b0;
            else if (state == PROCESS)
                status_out <= status_out | status_in; // 设置对应位
        end
    end
    
    // 状态机 - 组合逻辑
    always @(*) begin
        ready = 1'b0;
        next_state = state;
        
        case (state)
            IDLE: begin
                ready = 1'b1;  // 在IDLE状态时准备好接收数据
                if (valid && ready) begin
                    next_state = PROCESS;
                end
            end
            
            PROCESS: begin
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule