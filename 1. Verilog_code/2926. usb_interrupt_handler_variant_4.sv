//SystemVerilog
//IEEE 1364-2005 Verilog
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
    output reg [2:0] handler_state
);
    // 状态定义
    localparam IDLE = 3'b000;
    localparam FIND_START = 3'b001;
    localparam FIND_CALCULATE = 3'b010;
    localparam FIND_COMPLETE = 3'b011;
    localparam SCHEDULE = 3'b100;
    localparam WAIT = 3'b101;
    localparam COMPLETE = 3'b110;
    
    // Interval configuration for each endpoint (in frames)
    reg [7:0] interval [0:MAX_INT_ENDPOINTS-1];
    
    // Last serviced frame for each endpoint
    reg [10:0] last_frame [0:MAX_INT_ENDPOINTS-1];
    
    // 流水线寄存器
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_enabled_stage1;
    reg [MAX_INT_ENDPOINTS-1:0] data_ready_stage1;
    reg [10:0] frame_number_stage1;
    
    // 流水线中间计算结果
    reg [MAX_INT_ENDPOINTS-1:0] interval_check_result;
    reg [MAX_INT_ENDPOINTS-1:0] valid_endpoints;
    
    // 当前扫描端点索引
    reg [3:0] current_index;
    reg [3:0] candidate_endpoint;
    reg candidate_valid;
    
    // 时间间隔检查中间变量
    reg [10:0] frame_diff;
    reg [10:0] interval_threshold;
    reg interval_valid;
    
    // 端点状态评估中间变量
    reg endpoint_is_enabled;
    reg endpoint_has_data;
    reg endpoint_meets_interval;
    reg endpoint_is_valid;
    
    // 状态转换中间变量
    reg is_last_endpoint;
    reg transfer_is_complete;
    reg is_correct_endpoint;
    reg should_complete_transfer;
    
    // 初始化
    integer i;
    initial begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            interval[i] = 8'd8;  // Default to 8ms interval
            last_frame[i] = 11'd0;
        end
        
        current_index = 4'd0;
        candidate_valid = 1'b0;
        candidate_endpoint = 4'd0;
        endpoint_to_service = 4'd0;
        transfer_request = 1'b0;
        handler_state = IDLE;
        interval_check_result = {MAX_INT_ENDPOINTS{1'b0}};
        valid_endpoints = {MAX_INT_ENDPOINTS{1'b0}};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handler_state <= IDLE;
            endpoint_to_service <= 4'd0;
            transfer_request <= 1'b0;
            candidate_valid <= 1'b0;
            candidate_endpoint <= 4'd0;
            current_index <= 4'd0;
            
            endpoint_enabled_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            data_ready_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            frame_number_stage1 <= 11'd0;
            
            interval_check_result <= {MAX_INT_ENDPOINTS{1'b0}};
            valid_endpoints <= {MAX_INT_ENDPOINTS{1'b0}};
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                last_frame[i] <= 11'd0;
            end
        end else begin
            // 流水线第一级 - 寄存输入信号
            endpoint_enabled_stage1 <= endpoint_enabled;
            data_ready_stage1 <= data_ready;
            frame_number_stage1 <= frame_number;
            
            case(handler_state)
                IDLE: begin
                    transfer_request <= 1'b0;
                    current_index <= 4'd0;
                    candidate_valid <= 1'b0;
                    
                    // 预计算所有端点的间隔检查结果
                    for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                        // 分解复杂条件表达式
                        frame_diff = frame_number_stage1 - last_frame[i];
                        interval_threshold = {3'b000, interval[i]};
                        interval_valid = (frame_diff >= interval_threshold);
                        interval_check_result[i] <= interval_valid;
                    end
                    
                    if (sof_received)
                        handler_state <= FIND_START;
                end
                
                FIND_START: begin
                    // 流水线第二级 - 计算有效端点
                    for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                        // 分解复杂条件表达式
                        endpoint_is_enabled = endpoint_enabled_stage1[i];
                        endpoint_has_data = data_ready_stage1[i];
                        endpoint_meets_interval = interval_check_result[i];
                        
                        // 逐步判断
                        endpoint_is_valid = endpoint_is_enabled & endpoint_has_data & endpoint_meets_interval;
                        valid_endpoints[i] <= endpoint_is_valid;
                    end
                    
                    handler_state <= FIND_CALCULATE;
                end
                
                FIND_CALCULATE: begin
                    // 流水线第三级 - 迭代查找第一个有效端点
                    endpoint_is_valid = valid_endpoints[current_index];
                    
                    if (endpoint_is_valid && !candidate_valid) begin
                        candidate_endpoint <= current_index;
                        candidate_valid <= 1'b1;
                    end
                    
                    is_last_endpoint = (current_index == MAX_INT_ENDPOINTS-1);
                    
                    if (is_last_endpoint) begin
                        handler_state <= FIND_COMPLETE;
                    end else begin
                        current_index <= current_index + 1'b1;
                    end
                end
                
                FIND_COMPLETE: begin
                    // 流水线第四级 - 完成查找并做出决策
                    current_index <= 4'd0;
                    
                    if (candidate_valid) begin
                        endpoint_to_service <= candidate_endpoint;
                        handler_state <= SCHEDULE;
                    end else begin
                        handler_state <= IDLE;
                    end
                end
                
                SCHEDULE: begin
                    // 流水线第五级 - 发出传输请求
                    transfer_request <= 1'b1;
                    candidate_valid <= 1'b0;
                    handler_state <= WAIT;
                end
                
                WAIT: begin
                    transfer_is_complete = transfer_complete;
                    is_correct_endpoint = (completed_endpoint == endpoint_to_service);
                    should_complete_transfer = transfer_is_complete && is_correct_endpoint;
                    
                    if (should_complete_transfer) begin
                        last_frame[endpoint_to_service] <= frame_number_stage1;
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