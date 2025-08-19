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
    localparam CHECK = 2'b01;
    localparam RESPOND = 2'b10;
    localparam COMPLETE = 2'b11;
    
    reg [7:0] endpoint_buffer_status [0:15];  // Status for each endpoint
    reg [3:0] endpoint_stall_status;          // Stall status for endpoints
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_state_o <= IDLE;
            ack_response_o <= 1'b0;
            nak_response_o <= 1'b0;
            stall_response_o <= 1'b0;
            ping_handled_o <= 1'b0;
            endpoint_stall_status <= 4'h0;
        end else begin
            case (ping_state_o)
                IDLE: begin
                    ack_response_o <= 1'b0;
                    nak_response_o <= 1'b0;
                    stall_response_o <= 1'b0;
                    ping_handled_o <= 1'b0;
                    
                    if (ping_received_i)
                        ping_state_o <= CHECK;
                end
                CHECK: begin
                    if (endpoint_stall_status[endpoint_i]) begin
                        stall_response_o <= 1'b1;
                    end else if (buffer_status_i > 8'd0) begin  // Space available
                        ack_response_o <= 1'b1;
                    end else begin
                        nak_response_o <= 1'b1;
                    end
                    ping_state_o <= RESPOND;
                end
                RESPOND: begin
                    ping_handled_o <= 1'b1;
                    ping_state_o <= COMPLETE;
                end
                COMPLETE: begin
                    ack_response_o <= 1'b0;
                    nak_response_o <= 1'b0;
                    stall_response_o <= 1'b0;
                    ping_handled_o <= 1'b0;
                    ping_state_o <= IDLE;
                end
            endcase
        end
    end
endmodule