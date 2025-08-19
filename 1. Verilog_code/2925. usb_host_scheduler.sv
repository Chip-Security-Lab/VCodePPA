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
                IDLE: begin
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
                        
                        2'd1: begin // Next schedule INT transfers
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
                        
                        2'd2: begin // Next schedule CTRL transfers
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
                        
                        2'd3: begin // Finally schedule BULK transfers
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
                    endcase
                end
                
                EXECUTE: begin
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
                
                default: scheduler_state <= IDLE;
            endcase
        end
    end
endmodule