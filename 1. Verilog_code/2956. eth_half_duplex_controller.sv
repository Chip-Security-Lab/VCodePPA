module eth_half_duplex_controller (
    input wire clk,
    input wire rst_n,
    // MAC layer interface
    input wire tx_request,
    output reg tx_grant,
    input wire tx_complete,
    input wire rx_active,
    // Status signals
    output reg [3:0] backoff_attempts,
    output reg [15:0] backoff_time,
    output reg carrier_sense,
    output reg collision_detected
);
    localparam IDLE = 3'd0, SENSE = 3'd1, TRANSMIT = 3'd2;
    localparam COLLISION = 3'd3, BACKOFF = 3'd4, IFG = 3'd5;
    
    localparam IFG_TIME = 16'd12; // 12 byte times
    
    reg [2:0] state;
    reg [15:0] timer;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_grant <= 1'b0;
            backoff_attempts <= 4'd0;
            backoff_time <= 16'd0;
            carrier_sense <= 1'b0;
            collision_detected <= 1'b0;
            timer <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (tx_request) begin
                        state <= SENSE;
                        carrier_sense <= 1'b0;
                        collision_detected <= 1'b0;
                    end
                end
                
                SENSE: begin
                    // Check if medium is busy (carrier sense)
                    if (rx_active) begin
                        carrier_sense <= 1'b1;
                        state <= IDLE;
                    end else begin
                        carrier_sense <= 1'b0;
                        tx_grant <= 1'b1;
                        state <= TRANSMIT;
                    end
                end
                
                TRANSMIT: begin
                    // Check for collision during transmission
                    if (rx_active) begin
                        collision_detected <= 1'b1;
                        tx_grant <= 1'b0;
                        backoff_attempts <= (backoff_attempts < 15) ? backoff_attempts + 1'b1 : backoff_attempts;
                        state <= COLLISION;
                    end else if (tx_complete) begin
                        tx_grant <= 1'b0;
                        backoff_attempts <= 4'd0;
                        state <= IFG;
                        timer <= IFG_TIME;
                    end
                end
                
                COLLISION: begin
                    // Calculate backoff time using truncated binary exponential backoff
                    if (backoff_attempts <= 10) begin
                        // Use simple value for simulation: 2^n - 1
                        backoff_time <= (16'd1 << backoff_attempts) - 16'd1;
                    end else begin
                        backoff_time <= 16'd1023; // 2^10 - 1
                    end
                    
                    state <= BACKOFF;
                    timer <= backoff_time;
                    collision_detected <= 1'b0;
                end
                
                BACKOFF: begin
                    if (timer > 0) begin
                        timer <= timer - 16'd1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                IFG: begin
                    if (timer > 0) begin
                        timer <= timer - 16'd1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule