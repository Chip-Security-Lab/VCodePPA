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
    output reg [1:0] ping_state_o
);
    localparam IDLE = 2'b00;
    localparam CHECK_STAGE1 = 2'b01;
    localparam CHECK_STAGE2 = 2'b10;
    localparam CHECK_STAGE3 = 2'b11;
    
    reg [7:0] endpoint_buffer_status [0:15];  // Status for each endpoint
    reg [3:0] endpoint_stall_status;          // Stall status for endpoints
    
    // 多级流水线状态和信号
    reg [1:0] next_state;
    
    // 流水线寄存器 - 阶段1
    reg ping_received_stage1;
    reg [3:0] endpoint_stage1;
    reg [7:0] buffer_status_stage1;
    
    // 流水线寄存器 - 阶段2
    reg ping_valid_stage2;
    reg endpoint_stall_stage2;
    reg buffer_avail_stage2;
    reg [3:0] endpoint_stage2;
    
    // 流水线寄存器 - 阶段3
    reg will_stall_stage3;
    reg will_ack_stage3;
    reg will_nak_stage3;
    reg ping_valid_stage3;
    
    // 流水线阶段输出控制信号
    reg pipe_reset_all;
    reg pipe_advance;
    
    // 第一级流水线 - 捕获输入
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_received_stage1 <= 1'b0;
            endpoint_stage1 <= 4'h0;
            buffer_status_stage1 <= 8'h0;
        end else if (pipe_reset_all) begin
            ping_received_stage1 <= 1'b0;
            endpoint_stage1 <= 4'h0;
            buffer_status_stage1 <= 8'h0;
        end else if (pipe_advance) begin
            ping_received_stage1 <= ping_received_i;
            endpoint_stage1 <= endpoint_i;
            buffer_status_stage1 <= buffer_status_i;
        end
    end
    
    // 第二级流水线 - 预处理条件
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_valid_stage2 <= 1'b0;
            endpoint_stage2 <= 4'h0;
            endpoint_stall_stage2 <= 1'b0;
            buffer_avail_stage2 <= 1'b0;
        end else if (pipe_reset_all) begin
            ping_valid_stage2 <= 1'b0;
            endpoint_stage2 <= 4'h0;
            endpoint_stall_stage2 <= 1'b0;
            buffer_avail_stage2 <= 1'b0;
        end else if (pipe_advance) begin
            ping_valid_stage2 <= ping_received_stage1;
            endpoint_stage2 <= endpoint_stage1;
            endpoint_stall_stage2 <= endpoint_stall_status[endpoint_stage1];
            buffer_avail_stage2 <= (buffer_status_stage1 > 8'd0);
        end
    end
    
    // 第三级流水线 - 决策逻辑
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            will_stall_stage3 <= 1'b0;
            will_ack_stage3 <= 1'b0;
            will_nak_stage3 <= 1'b0;
            ping_valid_stage3 <= 1'b0;
        end else if (pipe_reset_all) begin
            will_stall_stage3 <= 1'b0;
            will_ack_stage3 <= 1'b0;
            will_nak_stage3 <= 1'b0;
            ping_valid_stage3 <= 1'b0;
        end else if (pipe_advance) begin
            will_stall_stage3 <= ping_valid_stage2 && endpoint_stall_stage2;
            will_ack_stage3 <= ping_valid_stage2 && !endpoint_stall_stage2 && buffer_avail_stage2;
            will_nak_stage3 <= ping_valid_stage2 && !endpoint_stall_stage2 && !buffer_avail_stage2;
            ping_valid_stage3 <= ping_valid_stage2;
        end
    end
    
    // 流水线状态控制逻辑
    always @(*) begin
        next_state = ping_state_o;
        pipe_advance = 1'b0;
        pipe_reset_all = 1'b0;
        
        case (ping_state_o)
            IDLE: begin
                pipe_advance = 1'b1;
                if (ping_received_i)
                    next_state = CHECK_STAGE1;
            end
            
            CHECK_STAGE1: begin
                pipe_advance = 1'b1;
                next_state = CHECK_STAGE2;
            end
            
            CHECK_STAGE2: begin
                pipe_advance = 1'b1;
                next_state = CHECK_STAGE3;
            end
            
            CHECK_STAGE3: begin
                pipe_reset_all = 1'b1;
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
                pipe_reset_all = 1'b1;
            end
        endcase
    end
    
    // 状态和输出寄存器
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_state_o <= IDLE;
            ack_response_o <= 1'b0;
            nak_response_o <= 1'b0;
            stall_response_o <= 1'b0;
            ping_handled_o <= 1'b0;
            endpoint_stall_status <= 4'h0;
        end else begin
            // 更新状态寄存器
            ping_state_o <= next_state;
            
            // 更新输出寄存器
            case (ping_state_o)
                IDLE: begin
                    ack_response_o <= 1'b0;
                    nak_response_o <= 1'b0;
                    stall_response_o <= 1'b0;
                    ping_handled_o <= 1'b0;
                end
                
                CHECK_STAGE1: begin
                    // 第一级流水线阶段 - 不更新输出
                end
                
                CHECK_STAGE2: begin
                    // 第二级流水线阶段 - 不更新输出
                end
                
                CHECK_STAGE3: begin
                    // 第三级流水线阶段 - 产生最终响应
                    ack_response_o <= will_ack_stage3;
                    nak_response_o <= will_nak_stage3;
                    stall_response_o <= will_stall_stage3;
                    ping_handled_o <= ping_valid_stage3;
                end
                
                default: begin
                    ack_response_o <= 1'b0;
                    nak_response_o <= 1'b0;
                    stall_response_o <= 1'b0;
                    ping_handled_o <= 1'b0;
                end
            endcase
        end
    end
endmodule