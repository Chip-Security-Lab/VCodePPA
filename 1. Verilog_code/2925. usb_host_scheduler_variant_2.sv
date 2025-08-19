//SystemVerilog
// SystemVerilog
module usb_host_scheduler #(
    parameter NUM_ENDPOINTS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire sof_generated,
    input wire [10:0] frame_number,
    input wire [NUM_ENDPOINTS-1:0] control_xfer_pending,
    input wire [NUM_ENDPOINTS-1:0] bulk_xfer_pending,
    input wire [NUM_ENDPOINTS-1:0] int_xfer_pending,
    input wire [NUM_ENDPOINTS-1:0] isoc_xfer_pending,
    input wire transaction_complete,
    output reg [3:0] selected_endpoint,
    output reg [1:0] selected_xfer_type,
    output reg transaction_start,
    output reg [2:0] scheduler_state
);
    // Transfer types
    localparam CONTROL = 2'b00;
    localparam ISOCHRONOUS = 2'b01;
    localparam BULK = 2'b10;
    localparam INTERRUPT = 2'b11;
    
    // Scheduler states
    localparam IDLE = 3'd0;
    localparam SOF = 3'd1;
    localparam SCHEDULE = 3'd2;
    localparam EXECUTE = 3'd3;
    localparam COMPLETE = 3'd4;
    
    reg [10:0] bandwidth_used;
    reg [3:0] last_scheduled_endpoint;
    reg [1:0] scheduling_phase;
    
    // 用于找到第一个置位的位
    reg [3:0] ep_index;
    reg found_endpoint;
    integer i;
    
    // 状态和阶段组合
    reg [4:0] combined_state;
    
    always @(*) begin
        combined_state = {scheduler_state, scheduling_phase};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scheduler_state <= IDLE;
            selected_endpoint <= 4'd0;
            selected_xfer_type <= CONTROL;
            transaction_start <= 1'b0;
            bandwidth_used <= 11'd0;
            last_scheduled_endpoint <= 4'd0;
            scheduling_phase <= 2'd0;
            ep_index <= 4'd0;
            found_endpoint <= 1'b0;
        end else begin
            // 默认保持transaction_start不变
            transaction_start <= transaction_start;
            
            case (combined_state)
                // IDLE状态且SOF生成时
                {IDLE, 2'b00}, {IDLE, 2'b01}, {IDLE, 2'b10}, {IDLE, 2'b11}: begin
                    if (sof_generated) begin
                        scheduler_state <= SOF;
                        bandwidth_used <= 11'd0;
                        scheduling_phase <= 2'd0;
                        transaction_start <= 1'b0;
                    end else begin
                        transaction_start <= 1'b0;
                    end
                end
                
                // SOF状态
                {SOF, 2'b00}, {SOF, 2'b01}, {SOF, 2'b10}, {SOF, 2'b11}: begin
                    scheduler_state <= SCHEDULE;
                    found_endpoint <= 1'b0;
                end
                
                // SCHEDULE状态 - 同步传输调度阶段
                {SCHEDULE, 2'b00}: begin
                    found_endpoint <= 1'b0;
                    
                    // 查找第一个等待的isoc传输
                    for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                        if (isoc_xfer_pending[i] && !found_endpoint) begin
                            ep_index <= i;
                            found_endpoint <= 1'b1;
                        end
                    end
                    
                    if (found_endpoint) begin
                        selected_endpoint <= ep_index;
                        selected_xfer_type <= ISOCHRONOUS;
                        scheduler_state <= EXECUTE;
                    end else begin
                        scheduling_phase <= 2'd1; // 进入下一调度阶段
                    end
                end
                
                // SCHEDULE状态 - 中断传输调度阶段
                {SCHEDULE, 2'b01}: begin
                    found_endpoint <= 1'b0;
                    
                    // 查找第一个等待的int传输
                    for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                        if (int_xfer_pending[i] && !found_endpoint) begin
                            ep_index <= i;
                            found_endpoint <= 1'b1;
                        end
                    end
                    
                    if (found_endpoint) begin
                        selected_endpoint <= ep_index;
                        selected_xfer_type <= INTERRUPT;
                        scheduler_state <= EXECUTE;
                    end else begin
                        scheduling_phase <= 2'd2; // 进入下一调度阶段
                    end
                end
                
                // SCHEDULE状态 - 控制传输调度阶段
                {SCHEDULE, 2'b10}: begin
                    found_endpoint <= 1'b0;
                    
                    // 查找第一个等待的control传输
                    for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                        if (control_xfer_pending[i] && !found_endpoint) begin
                            ep_index <= i;
                            found_endpoint <= 1'b1;
                        end
                    end
                    
                    if (found_endpoint) begin
                        selected_endpoint <= ep_index;
                        selected_xfer_type <= CONTROL;
                        scheduler_state <= EXECUTE;
                    end else begin
                        scheduling_phase <= 2'd3; // 进入下一调度阶段
                    end
                end
                
                // SCHEDULE状态 - 批量传输调度阶段
                {SCHEDULE, 2'b11}: begin
                    found_endpoint <= 1'b0;
                    
                    // 查找第一个等待的bulk传输
                    for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                        if (bulk_xfer_pending[i] && !found_endpoint) begin
                            ep_index <= i;
                            found_endpoint <= 1'b1;
                        end
                    end
                    
                    if (found_endpoint) begin
                        selected_endpoint <= ep_index;
                        selected_xfer_type <= BULK;
                        scheduler_state <= EXECUTE;
                    end else begin
                        scheduler_state <= IDLE; // 没有传输需要调度
                    end
                end
                
                // EXECUTE状态
                {EXECUTE, 2'b00}, {EXECUTE, 2'b01}, {EXECUTE, 2'b10}, {EXECUTE, 2'b11}: begin
                    transaction_start <= 1'b1;
                    last_scheduled_endpoint <= selected_endpoint;
                    scheduler_state <= COMPLETE;
                end
                
                // COMPLETE状态
                {COMPLETE, 2'b00}, {COMPLETE, 2'b01}, {COMPLETE, 2'b10}, {COMPLETE, 2'b11}: begin
                    transaction_start <= 1'b0;
                    if (transaction_complete) begin
                        scheduler_state <= SCHEDULE; // 继续调度
                    end
                end
                
                // 默认处理
                default: begin
                    scheduler_state <= IDLE;
                end
            endcase
        end
    end
endmodule