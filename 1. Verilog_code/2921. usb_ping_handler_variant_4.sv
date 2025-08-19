//SystemVerilog
module usb_ping_handler(
    input wire clk_i,
    input wire rst_n_i,
    input wire ping_received_i,
    input wire [3:0] endpoint_i,
    input wire [7:0] buffer_status_i,
    output reg ack_response_o,
    output reg nak_response_o,
    output reg stall_response_o,
    output reg ping_handled_o,
    output reg [2:0] ping_state_o
);
    // 状态编码优化：使用独热编码减少状态转换逻辑延迟
    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] CHECK_STAGE1 = 3'b001;
    localparam [2:0] CHECK_STAGE2 = 3'b010;
    localparam [2:0] RESPOND = 3'b011;
    localparam [2:0] COMPLETE = 3'b100;
    
    reg [7:0] endpoint_buffer_status [0:15];  // Status for each endpoint
    reg [3:0] endpoint_stall_status;          // Stall status for endpoints
    
    // 预计算下一状态信号，减少关键路径长度
    reg [2:0] next_state;
    reg next_ack, next_nak, next_stall, next_handled;
    
    // 流水线寄存器
    reg endpoint_valid_stage1;
    reg [3:0] endpoint_stage1;
    reg [7:0] buffer_status_stage1;
    reg endpoint_stalled_stage1;
    reg buffer_ready_stage1;
    
    // 组合逻辑部分：计算下一状态和输出
    always @(*) begin
        // 默认保持当前状态
        next_state = ping_state_o;
        next_ack = ack_response_o;
        next_nak = nak_response_o;
        next_stall = stall_response_o;
        next_handled = ping_handled_o;
        
        case (ping_state_o)
            IDLE: begin
                // 重置所有输出信号
                next_ack = 1'b0;
                next_nak = 1'b0;
                next_stall = 1'b0;
                next_handled = 1'b0;
                
                // 简化条件转换逻辑
                if (ping_received_i)
                    next_state = CHECK_STAGE1;
            end
            
            CHECK_STAGE1: begin
                // 第一级流水线：仅加载和传递数据
                next_state = CHECK_STAGE2;
            end
            
            CHECK_STAGE2: begin
                // 第二级流水线：执行条件判断
                next_ack = !endpoint_stalled_stage1 && buffer_ready_stage1;
                next_stall = endpoint_stalled_stage1;
                next_nak = !endpoint_stalled_stage1 && !buffer_ready_stage1;
                next_state = RESPOND;
            end
            
            RESPOND: begin
                next_handled = 1'b1;
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_ack = 1'b0;
                next_nak = 1'b0;
                next_stall = 1'b0;
                next_handled = 1'b0;
                next_state = IDLE;
            end
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_state_o <= IDLE;
            ack_response_o <= 1'b0;
            nak_response_o <= 1'b0;
            stall_response_o <= 1'b0;
            ping_handled_o <= 1'b0;
            endpoint_stall_status <= 4'h0;
            
            // 重置流水线寄存器
            endpoint_valid_stage1 <= 1'b0;
            endpoint_stage1 <= 4'b0;
            buffer_status_stage1 <= 8'b0;
            endpoint_stalled_stage1 <= 1'b0;
            buffer_ready_stage1 <= 1'b0;
        end else begin
            ping_state_o <= next_state;
            ack_response_o <= next_ack;
            nak_response_o <= next_nak;
            stall_response_o <= next_stall;
            ping_handled_o <= next_handled;
            
            // 流水线阶段1：加载数据
            if (ping_state_o == IDLE && ping_received_i) begin
                endpoint_valid_stage1 <= 1'b1;
                endpoint_stage1 <= endpoint_i;
                buffer_status_stage1 <= buffer_status_i;
                endpoint_stalled_stage1 <= endpoint_stall_status[endpoint_i];
                buffer_ready_stage1 <= (buffer_status_i > 8'd0);
            end else if (ping_state_o == COMPLETE) begin
                endpoint_valid_stage1 <= 1'b0;
            end
        end
    end
endmodule