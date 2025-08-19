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
    // Synthesize using IEEE 1364-2005 Verilog standard
    
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
    
    // Frame difference calculation for interval comparison
    reg [10:0] frame_diff [0:MAX_INT_ENDPOINTS-1];
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_ready_for_service;
    
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
    
    // Pre-compute frame differences and ready status for all endpoints
    always @(*) begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            frame_diff[i] = frame_number - last_frame[i];
            endpoint_ready_for_service[i] = endpoint_enabled[i] && 
                                           data_ready[i] && 
                                           (frame_diff[i] >= {3'b000, interval[i]});
        end
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
                    
                    if (sof_received) begin
                        handler_state <= SCHEDULE;
                    end else begin
                        handler_state <= IDLE;
                    end
                end
                
                SCHEDULE: begin
                    found_endpoint <= 1'b0;
                    transfer_request <= 1'b0;
                    
                    // Implement optimized priority encoder using if-else structure
                    if (endpoint_ready_for_service[0]) begin
                        endpoint_to_service <= 4'd0;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[1]) begin
                        endpoint_to_service <= 4'd1;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[2]) begin
                        endpoint_to_service <= 4'd2;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[3]) begin
                        endpoint_to_service <= 4'd3;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[4]) begin
                        endpoint_to_service <= 4'd4;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[5]) begin
                        endpoint_to_service <= 4'd5;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[6]) begin
                        endpoint_to_service <= 4'd6;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else if (endpoint_ready_for_service[7]) begin
                        endpoint_to_service <= 4'd7;
                        transfer_request <= 1'b1;
                        found_endpoint <= 1'b1;
                    end else begin
                        found_endpoint <= 1'b0;
                        transfer_request <= 1'b0;
                    end
                    
                    if (found_endpoint) begin
                        handler_state <= WAIT;
                    end else begin
                        handler_state <= IDLE;
                    end
                end
                
                WAIT: begin
                    if (transfer_complete && completed_endpoint == endpoint_to_service) begin
                        last_frame[endpoint_to_service] <= frame_number;
                        transfer_request <= 1'b0;
                        handler_state <= COMPLETE;
                    end else begin
                        handler_state <= WAIT;
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