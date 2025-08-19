//SystemVerilog
module usb_interrupt_handler #(
    parameter MAX_INT_ENDPOINTS = 8,
    parameter MAX_INTERVAL = 255
)(
    input wire clk,
    input wire rst_n,
    input wire [10:0] frame_number,
    input wire sof_received,
    input wire [MAX_INT_ENDPOINTS-1:0] endpoint_enabled,
    input wire [MAX_INT_ENDPOINTS-1:0] data_ready,
    input wire transfer_complete,
    input wire [3:0] completed_endpoint,
    output reg [3:0] endpoint_to_service,
    output reg transfer_request,
    output reg [1:0] handler_state
);
    localparam IDLE = 2'b00;
    localparam SCHEDULE = 2'b01;
    localparam WAIT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // 寄存器移位 - 注册输入信号以减少输入到第一级寄存器的延迟
    reg [10:0] frame_number_reg;
    reg sof_received_reg;
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_enabled_reg;
    reg [MAX_INT_ENDPOINTS-1:0] data_ready_reg;
    reg transfer_complete_reg;
    reg [3:0] completed_endpoint_reg;
    
    // Interval configuration for each endpoint (in frames)
    reg [7:0] interval [0:MAX_INT_ENDPOINTS-1];
    
    // Last serviced frame for each endpoint
    reg [10:0] last_frame [0:MAX_INT_ENDPOINTS-1];
    
    // Eligibility and priority signals - 移到组合逻辑中
    wire [MAX_INT_ENDPOINTS-1:0] endpoint_eligible;
    wire [MAX_INT_ENDPOINTS-1:0] endpoint_priority;
    
    // Find first endpoint variables
    wire found_endpoint;
    integer i;
    
    // 注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_number_reg <= 11'd0;
            sof_received_reg <= 1'b0;
            endpoint_enabled_reg <= {MAX_INT_ENDPOINTS{1'b0}};
            data_ready_reg <= {MAX_INT_ENDPOINTS{1'b0}};
            transfer_complete_reg <= 1'b0;
            completed_endpoint_reg <= 4'd0;
        end else begin
            frame_number_reg <= frame_number;
            sof_received_reg <= sof_received;
            endpoint_enabled_reg <= endpoint_enabled;
            data_ready_reg <= data_ready;
            transfer_complete_reg <= transfer_complete;
            completed_endpoint_reg <= completed_endpoint;
        end
    end
    
    // Initialize default intervals
    initial begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            interval[i] = 8'd8;  // Default to 8ms interval
            last_frame[i] = 11'd0;
        end
    end
    
    // Pre-compute eligible endpoints - 转为组合逻辑，使用已注册的输入
    generate
        genvar g;
        for (g = 0; g < MAX_INT_ENDPOINTS; g = g + 1) begin : gen_eligible
            assign endpoint_eligible[g] = endpoint_enabled_reg[g] && data_ready_reg[g] && 
                                      ((frame_number_reg >= last_frame[g]) && 
                                       (frame_number_reg - last_frame[g] >= {3'b000, interval[g]}));
        end
    endgenerate
    
    // 优化的优先级编码器 - 采用并行查找方法
    wire [MAX_INT_ENDPOINTS-1:0] priority_mask;
    wire [3:0] encoded_endpoint;
    
    assign found_endpoint = |endpoint_eligible;
    
    // 采用独热码优化的优先级编码 - 将存在多级级联的逻辑转换为并行结构
    // 为每个位生成掩码 - 只保留最低位的1
    assign priority_mask[0] = endpoint_eligible[0];
    generate
        for (g = 1; g < MAX_INT_ENDPOINTS; g = g + 1) begin : gen_mask
            assign priority_mask[g] = endpoint_eligible[g] & ~(|endpoint_eligible[g-1:0]);
        end
    endgenerate
    
    // 编码优先级，更高效的并行实现
    assign encoded_endpoint = (priority_mask[0]) ? 4'd0 :
                              (priority_mask[1]) ? 4'd1 :
                              (priority_mask[2]) ? 4'd2 :
                              (priority_mask[3]) ? 4'd3 :
                              (priority_mask[4]) ? 4'd4 :
                              (priority_mask[5]) ? 4'd5 :
                              (priority_mask[6]) ? 4'd6 :
                              (priority_mask[7]) ? 4'd7 : 4'd0;
    
    // 主状态机 - 使用已注册的信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handler_state <= IDLE;
            transfer_request <= 1'b0;
            endpoint_to_service <= 4'd0;
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                last_frame[i] <= 11'd0;
            end
        end else begin
            case(handler_state)
                IDLE: begin
                    transfer_request <= 1'b0;
                    
                    if (sof_received_reg)
                        handler_state <= SCHEDULE;
                end
                
                SCHEDULE: begin
                    // 使用预先计算的优先级
                    transfer_request <= found_endpoint;
                    endpoint_to_service <= encoded_endpoint;
                    
                    if (found_endpoint)
                        handler_state <= WAIT;
                    else
                        handler_state <= IDLE;
                end
                
                WAIT: begin
                    if (transfer_complete_reg && completed_endpoint_reg == endpoint_to_service) begin
                        last_frame[endpoint_to_service] <= frame_number_reg;
                        transfer_request <= 1'b0;
                        handler_state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    handler_state <= IDLE;
                end
                
                default: handler_state <= IDLE;
            endcase
        end
    end
endmodule