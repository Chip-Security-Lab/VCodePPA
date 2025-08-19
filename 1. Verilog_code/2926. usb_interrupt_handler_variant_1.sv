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
    // 状态编码定义
    localparam IDLE = 2'b00;
    localparam SCHEDULE = 2'b01;
    localparam WAIT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // 端点配置存储
    reg [7:0] interval [0:MAX_INT_ENDPOINTS-1];
    reg [10:0] last_frame [0:MAX_INT_ENDPOINTS-1];
    
    // 中间变量和计算结果
    reg found_endpoint;
    integer i;
    
    // 用于端点判断的向量化逻辑
    reg [MAX_INT_ENDPOINTS-1:0] qualified_endpoints;
    wire [MAX_INT_ENDPOINTS-1:0] endpoint_interval_met;
    
    // 时间差计算
    reg [10:0] frame_diff [0:MAX_INT_ENDPOINTS-1];
    
    // 初始化默认配置
    initial begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            interval[i] = 8'd8;  // 默认8ms间隔
            last_frame[i] = 11'd0;
        end
        
        found_endpoint = 1'b0;
        endpoint_to_service = 4'd0;
        transfer_request = 1'b0;
        handler_state = IDLE;
    end
    
    // 优化比较逻辑：预计算所有端点的时间差
    always @(*) begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            frame_diff[i] = frame_number - last_frame[i];
        end
    end
    
    // 生成端点资格判断向量
    genvar g;
    generate
        for (g = 0; g < MAX_INT_ENDPOINTS; g = g + 1) begin : endpoint_check
            assign endpoint_interval_met[g] = (frame_diff[g] >= {3'b000, interval[g]});
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            handler_state <= IDLE;
            endpoint_to_service <= 4'd0;
            transfer_request <= 1'b0;
            found_endpoint <= 1'b0;
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                last_frame[i] <= 11'd0;
            end
        end else begin
            case(handler_state)
                IDLE: begin
                    // 清除转移请求
                    transfer_request <= 1'b0;
                    found_endpoint <= 1'b0;
                    
                    // 当SOF接收到时转换到调度状态
                    if (sof_received)
                        handler_state <= SCHEDULE;
                end
                
                SCHEDULE: begin
                    found_endpoint <= 1'b0;
                    
                    // 预计算所有合格端点的向量
                    qualified_endpoints = endpoint_enabled & data_ready & endpoint_interval_met;
                    
                    // 优先级编码器查找最低位的已设置位
                    if (qualified_endpoints != 0) begin
                        found_endpoint <= 1'b1;
                        transfer_request <= 1'b1;
                        
                        // 确定优先级最高的端点 (最低索引)
                        if (qualified_endpoints[0]) endpoint_to_service <= 4'd0;
                        else if (qualified_endpoints[1]) endpoint_to_service <= 4'd1;
                        else if (qualified_endpoints[2]) endpoint_to_service <= 4'd2;
                        else if (qualified_endpoints[3]) endpoint_to_service <= 4'd3;
                        else if (qualified_endpoints[4]) endpoint_to_service <= 4'd4;
                        else if (qualified_endpoints[5]) endpoint_to_service <= 4'd5;
                        else if (qualified_endpoints[6]) endpoint_to_service <= 4'd6;
                        else endpoint_to_service <= 4'd7;
                    end
                    
                    // 基于查找结果确定下一个状态
                    handler_state <= qualified_endpoints ? WAIT : IDLE;
                end
                
                WAIT: begin
                    // 检查是否完成传输
                    if (transfer_complete && (completed_endpoint == endpoint_to_service)) begin
                        last_frame[endpoint_to_service] <= frame_number;
                        transfer_request <= 1'b0;
                        handler_state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    // 完成处理后返回空闲状态
                    handler_state <= IDLE;
                end
                
                default: handler_state <= IDLE;
            endcase
        end
    end
endmodule