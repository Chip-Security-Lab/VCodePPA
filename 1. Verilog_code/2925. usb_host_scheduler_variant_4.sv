//SystemVerilog
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
    
    // 预寄存器输入信号以改善时序性能
    reg sof_generated_r;
    reg transaction_complete_r;
    reg [NUM_ENDPOINTS-1:0] control_xfer_pending_r;
    reg [NUM_ENDPOINTS-1:0] bulk_xfer_pending_r;
    reg [NUM_ENDPOINTS-1:0] int_xfer_pending_r;
    reg [NUM_ENDPOINTS-1:0] isoc_xfer_pending_r;
    
    // 端点优先级数组 - 用于更高效地找到具有待处理传输的端点
    reg [NUM_ENDPOINTS-1:0] priority_xfer [0:3];  
    reg [3:0] next_endpoint [0:3];
    reg [3:0] found_xfer;
    
    // 将输入寄存器化，减少输入到第一级逻辑之间的延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sof_generated_r <= 1'b0;
            transaction_complete_r <= 1'b0;
            control_xfer_pending_r <= {NUM_ENDPOINTS{1'b0}};
            bulk_xfer_pending_r <= {NUM_ENDPOINTS{1'b0}};
            int_xfer_pending_r <= {NUM_ENDPOINTS{1'b0}};
            isoc_xfer_pending_r <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            sof_generated_r <= sof_generated;
            transaction_complete_r <= transaction_complete;
            control_xfer_pending_r <= control_xfer_pending;
            bulk_xfer_pending_r <= bulk_xfer_pending;
            int_xfer_pending_r <= int_xfer_pending;
            isoc_xfer_pending_r <= isoc_xfer_pending;
        end
    end
    
    // 使用优化的优先编码器来查找第一个待处理传输的端点
    function automatic [3:0] find_first_endpoint;
        input [NUM_ENDPOINTS-1:0] pending_vector;
        reg [3:0] result;
        reg found;
        integer i;
        begin
            result = 4'hF;  // 默认无效值
            found = 1'b0;
            
            // 优化版本的优先编码器 - 从MSB到LSB扫描
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                if (pending_vector[i] && !found) begin
                    result = i[3:0];
                    found = 1'b1;
                end
            end
            
            find_first_endpoint = result;
        end
    endfunction
    
    // 并行计算每种传输类型的下一个端点
    always @(*) begin
        priority_xfer[ISOCHRONOUS] = isoc_xfer_pending_r;
        priority_xfer[INTERRUPT] = int_xfer_pending_r;
        priority_xfer[CONTROL] = control_xfer_pending_r;
        priority_xfer[BULK] = bulk_xfer_pending_r;
        
        // 并行查找每种传输类型的下一个端点
        next_endpoint[ISOCHRONOUS] = find_first_endpoint(priority_xfer[ISOCHRONOUS]);
        next_endpoint[INTERRUPT] = find_first_endpoint(priority_xfer[INTERRUPT]);
        next_endpoint[CONTROL] = find_first_endpoint(priority_xfer[CONTROL]);
        next_endpoint[BULK] = find_first_endpoint(priority_xfer[BULK]);
        
        // 确定哪些传输类型有待处理的传输
        found_xfer[ISOCHRONOUS] = (next_endpoint[ISOCHRONOUS] != 4'hF);
        found_xfer[INTERRUPT] = (next_endpoint[INTERRUPT] != 4'hF);
        found_xfer[CONTROL] = (next_endpoint[CONTROL] != 4'hF);
        found_xfer[BULK] = (next_endpoint[BULK] != 4'hF);
    end
    
    // 主状态机和调度逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scheduler_state <= IDLE;
            selected_endpoint <= 4'd0;
            selected_xfer_type <= CONTROL;
            transaction_start <= 1'b0;
            bandwidth_used <= 11'd0;
            last_scheduled_endpoint <= 4'd0;
            scheduling_phase <= 2'd0;
        end else begin
            case(scheduler_state)
                IDLE: begin
                    transaction_start <= 1'b0;
                    if (sof_generated_r) begin
                        scheduler_state <= SOF;
                        bandwidth_used <= 11'd0;
                        scheduling_phase <= 2'd0;  // Reset scheduling phase
                    end
                end
                
                SOF: begin
                    scheduler_state <= SCHEDULE;
                end
                
                SCHEDULE: begin
                    // 使用更高效的并行比较逻辑
                    case (scheduling_phase)
                        2'd0: begin  // ISOC transfers have highest priority
                            if (found_xfer[ISOCHRONOUS]) begin
                                selected_endpoint <= next_endpoint[ISOCHRONOUS];
                                selected_xfer_type <= ISOCHRONOUS;
                                scheduler_state <= EXECUTE;
                            end else begin
                                scheduling_phase <= 2'd1;
                            end
                        end
                        
                        2'd1: begin  // INT transfers have next priority
                            if (found_xfer[INTERRUPT]) begin
                                selected_endpoint <= next_endpoint[INTERRUPT];
                                selected_xfer_type <= INTERRUPT;
                                scheduler_state <= EXECUTE;
                            end else begin
                                scheduling_phase <= 2'd2;
                            end
                        end
                        
                        2'd2: begin  // CTRL transfers have next priority
                            if (found_xfer[CONTROL]) begin
                                selected_endpoint <= next_endpoint[CONTROL];
                                selected_xfer_type <= CONTROL;
                                scheduler_state <= EXECUTE;
                            end else begin
                                scheduling_phase <= 2'd3;
                            end
                        end
                        
                        2'd3: begin  // BULK transfers have lowest priority
                            if (found_xfer[BULK]) begin
                                selected_endpoint <= next_endpoint[BULK];
                                selected_xfer_type <= BULK;
                                scheduler_state <= EXECUTE;
                            end else begin
                                scheduler_state <= IDLE;  // No transfers to schedule
                            end
                        end
                    endcase
                end
                
                EXECUTE: begin
                    transaction_start <= 1'b1;
                    last_scheduled_endpoint <= selected_endpoint;
                    scheduler_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    transaction_start <= 1'b0;
                    if (transaction_complete_r) begin
                        scheduler_state <= SCHEDULE;  // Continue scheduling
                    end
                end
                
                default: scheduler_state <= IDLE;
            endcase
        end
    end
endmodule