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
    
    // Interval configuration for each endpoint (in frames)
    reg [7:0] interval [0:MAX_INT_ENDPOINTS-1];
    
    // Last serviced frame for each endpoint
    reg [10:0] last_frame [0:MAX_INT_ENDPOINTS-1];
    
    // Find first endpoint variables
    reg found_endpoint;
    integer i;
    
    // Initialize default intervals
    initial begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            interval[i] = 8'd8;  // Default to 8ms interval
            last_frame[i] = 11'd0;
        end
        
        found_endpoint = 1'b0;
        endpoint_to_service = 4'd0;
        transfer_request = 1'b0;
        handler_state = IDLE;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
                    transfer_request <= 1'b0;
                    found_endpoint <= 1'b0;
                    
                    if (sof_received)
                        handler_state <= SCHEDULE;
                end
                
                SCHEDULE: begin
                    found_endpoint <= 1'b0;
                    
                    // 查找需要服务的端点
                    for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                        if (endpoint_enabled[i] && data_ready[i] &&
                           (frame_number - last_frame[i] >= {3'b000, interval[i]}) &&
                           !found_endpoint) begin
                            endpoint_to_service <= i;
                            transfer_request <= 1'b1;
                            found_endpoint <= 1'b1;
                        end
                    end
                    
                    if (found_endpoint)
                        handler_state <= WAIT;
                    else
                        handler_state <= IDLE;
                end
                
                WAIT: begin
                    if (transfer_complete && completed_endpoint == endpoint_to_service) begin
                        last_frame[endpoint_to_service] <= frame_number;
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