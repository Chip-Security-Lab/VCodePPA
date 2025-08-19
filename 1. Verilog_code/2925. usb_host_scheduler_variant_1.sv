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
    
    // 用于找到第一个置位的位
    reg [3:0] ep_index;
    reg found_endpoint;
    integer i;
    
    // 缓冲寄存器 - 高扇出信号的缓冲器
    reg [2:0] idle_buf [1:0];       // IDLE状态缓冲
    reg [2:0] execute_buf [1:0];    // EXECUTE状态缓冲
    reg [3:0] ep_index_buf [1:0];   // ep_index缓冲
    
    // 参数NUM_ENDPOINTS的缓冲器
    reg [7:0] num_ep_buf [3:0];    // 针对NUM_ENDPOINTS的多级缓冲
    
    // 针对搜索逻辑的d0状态缓冲器
    reg [NUM_ENDPOINTS-1:0] d0_isoc_buf [1:0];
    reg [NUM_ENDPOINTS-1:0] d0_int_buf [1:0];
    reg [NUM_ENDPOINTS-1:0] d0_ctrl_buf [1:0];
    reg [NUM_ENDPOINTS-1:0] d0_bulk_buf [1:0];
    
    // 高扇出信号的初始化和缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化缓冲寄存器
            for (i = 0; i < 2; i = i + 1) begin
                idle_buf[i] <= IDLE;
                execute_buf[i] <= EXECUTE;
                ep_index_buf[i] <= 4'd0;
            end
            
            for (i = 0; i < 4; i = i + 1) begin
                num_ep_buf[i] <= NUM_ENDPOINTS;
            end
            
            for (i = 0; i < 2; i = i + 1) begin
                d0_isoc_buf[i] <= {NUM_ENDPOINTS{1'b0}};
                d0_int_buf[i] <= {NUM_ENDPOINTS{1'b0}};
                d0_ctrl_buf[i] <= {NUM_ENDPOINTS{1'b0}};
                d0_bulk_buf[i] <= {NUM_ENDPOINTS{1'b0}};
            end
        end else begin
            // 更新缓冲链
            idle_buf[0] <= IDLE;
            idle_buf[1] <= idle_buf[0];
            
            execute_buf[0] <= EXECUTE;
            execute_buf[1] <= execute_buf[0];
            
            ep_index_buf[0] <= ep_index;
            ep_index_buf[1] <= ep_index_buf[0];
            
            // 更新NUM_ENDPOINTS多级缓冲
            num_ep_buf[0] <= NUM_ENDPOINTS;
            for (i = 1; i < 4; i = i + 1) begin
                num_ep_buf[i] <= num_ep_buf[i-1];
            end
            
            // 更新数据路径缓冲
            d0_isoc_buf[0] <= isoc_xfer_pending;
            d0_isoc_buf[1] <= d0_isoc_buf[0];
            
            d0_int_buf[0] <= int_xfer_pending;
            d0_int_buf[1] <= d0_int_buf[0];
            
            d0_ctrl_buf[0] <= control_xfer_pending;
            d0_ctrl_buf[1] <= d0_ctrl_buf[0];
            
            d0_bulk_buf[0] <= bulk_xfer_pending;
            d0_bulk_buf[1] <= d0_bulk_buf[0];
        end
    end
    
    // 主状态机逻辑
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
            case(scheduler_state)
                idle_buf[1]: begin  // 使用缓冲的IDLE状态常量
                    transaction_start <= 1'b0;
                    if (sof_generated) begin
                        scheduler_state <= SOF;
                        bandwidth_used <= 11'd0;
                        scheduling_phase <= 2'd0;  // Reset scheduling phase
                    end
                end
                
                SOF: begin
                    scheduler_state <= SCHEDULE;
                    found_endpoint <= 1'b0;
                end
                
                SCHEDULE: begin
                    case (scheduling_phase)
                        2'd0: begin // First schedule ISOC transfers
                            found_endpoint <= 1'b0;
                            
                            // 使用缓冲的信号进行查找
                            for (i = 0; i < num_ep_buf[0]; i = i + 1) begin
                                if (d0_isoc_buf[1][i] && !found_endpoint) begin
                                    ep_index <= i;
                                    found_endpoint <= 1'b1;
                                end
                            end
                            
                            if (found_endpoint) begin
                                selected_endpoint <= ep_index_buf[1];
                                selected_xfer_type <= ISOCHRONOUS;
                                scheduler_state <= execute_buf[1];  // 使用缓冲的EXECUTE状态
                            end else begin
                                scheduling_phase <= 2'd1; // 进入下一调度阶段
                            end
                        end
                        
                        2'd1: begin // Next schedule INT transfers
                            found_endpoint <= 1'b0;
                            
                            // 使用缓冲的信号进行查找
                            for (i = 0; i < num_ep_buf[1]; i = i + 1) begin
                                if (d0_int_buf[1][i] && !found_endpoint) begin
                                    ep_index <= i;
                                    found_endpoint <= 1'b1;
                                end
                            end
                            
                            if (found_endpoint) begin
                                selected_endpoint <= ep_index_buf[1];
                                selected_xfer_type <= INTERRUPT;
                                scheduler_state <= execute_buf[1];  // 使用缓冲的EXECUTE状态
                            end else begin
                                scheduling_phase <= 2'd2; // 进入下一调度阶段
                            end
                        end
                        
                        2'd2: begin // Next schedule CTRL transfers
                            found_endpoint <= 1'b0;
                            
                            // 使用缓冲的信号进行查找
                            for (i = 0; i < num_ep_buf[2]; i = i + 1) begin
                                if (d0_ctrl_buf[1][i] && !found_endpoint) begin
                                    ep_index <= i;
                                    found_endpoint <= 1'b1;
                                end
                            end
                            
                            if (found_endpoint) begin
                                selected_endpoint <= ep_index_buf[1];
                                selected_xfer_type <= CONTROL;
                                scheduler_state <= execute_buf[1];  // 使用缓冲的EXECUTE状态
                            end else begin
                                scheduling_phase <= 2'd3; // 进入下一调度阶段
                            end
                        end
                        
                        2'd3: begin // Finally schedule BULK transfers
                            found_endpoint <= 1'b0;
                            
                            // 使用缓冲的信号进行查找
                            for (i = 0; i < num_ep_buf[3]; i = i + 1) begin
                                if (d0_bulk_buf[1][i] && !found_endpoint) begin
                                    ep_index <= i;
                                    found_endpoint <= 1'b1;
                                end
                            end
                            
                            if (found_endpoint) begin
                                selected_endpoint <= ep_index_buf[1];
                                selected_xfer_type <= BULK;
                                scheduler_state <= execute_buf[1];  // 使用缓冲的EXECUTE状态
                            end else begin
                                scheduler_state <= idle_buf[1]; // 使用缓冲的IDLE状态
                            end
                        end
                    endcase
                end
                
                execute_buf[1]: begin  // 使用缓冲的EXECUTE状态
                    transaction_start <= 1'b1;
                    last_scheduled_endpoint <= selected_endpoint;
                    scheduler_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    transaction_start <= 1'b0;
                    if (transaction_complete) begin
                        scheduler_state <= SCHEDULE; // 继续调度
                    end
                end
                
                default: scheduler_state <= idle_buf[1];  // 使用缓冲的IDLE状态
            endcase
        end
    end
endmodule