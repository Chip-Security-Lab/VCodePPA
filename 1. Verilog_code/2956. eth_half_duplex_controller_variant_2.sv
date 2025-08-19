//SystemVerilog
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
    // State definitions
    localparam IDLE = 3'd0, SENSE = 3'd1, TRANSMIT = 3'd2;
    localparam COLLISION = 3'd3, BACKOFF = 3'd4, IFG = 3'd5;
    
    localparam IFG_TIME = 16'd12; // 12 byte times
    
    reg [2:0] state, next_state;
    reg [15:0] timer, next_timer;
    reg next_tx_grant;
    reg [3:0] next_backoff_attempts;
    reg [15:0] next_backoff_time;
    reg next_carrier_sense;
    reg next_collision_detected;

    // Buffer registers for high fanout signals
    reg [2:0] state_buf1, state_buf2;
    reg [3:0] backoff_attempts_buf1, backoff_attempts_buf2;
    reg [2:0] next_state_buf1, next_state_buf2;
    
    // IDLE state buffering
    reg idle_match_buf1, idle_match_buf2;
    
    // State register with buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            timer <= 16'd0;
            // Initialize buffer registers
            state_buf1 <= IDLE;
            state_buf2 <= IDLE;
        end else begin
            state <= next_state;
            timer <= next_timer;
            // Update buffer registers
            state_buf1 <= state;
            state_buf2 <= state_buf1;
        end
    end
    
    // Next state buffer registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
        end else begin
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state_buf1;
        end
    end
    
    // IDLE state match buffer registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idle_match_buf1 <= 1'b1;
            idle_match_buf2 <= 1'b1;
        end else begin
            idle_match_buf1 <= (state == IDLE);
            idle_match_buf2 <= idle_match_buf1;
        end
    end

    // Output registers with backoff_attempts buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_grant <= 1'b0;
            backoff_attempts <= 4'd0;
            backoff_time <= 16'd0;
            carrier_sense <= 1'b0;
            collision_detected <= 1'b0;
            // Initialize backoff_attempts buffers
            backoff_attempts_buf1 <= 4'd0;
            backoff_attempts_buf2 <= 4'd0;
        end else begin
            tx_grant <= next_tx_grant;
            backoff_attempts <= next_backoff_attempts;
            backoff_time <= next_backoff_time;
            carrier_sense <= next_carrier_sense;
            collision_detected <= next_collision_detected;
            // Update backoff_attempts buffers
            backoff_attempts_buf1 <= backoff_attempts;
            backoff_attempts_buf2 <= backoff_attempts_buf1;
        end
    end

    // Helper registers for complex calculations
    reg [15:0] backoff_calc_result;
    
    // Pre-calculate backoff time to reduce path delay
    always @(posedge clk) begin
        if (backoff_attempts_buf1 <= 10) begin
            backoff_calc_result <= (16'd1 << backoff_attempts_buf1) - 16'd1;
        end else begin
            backoff_calc_result <= 16'd1023; // 2^10 - 1
        end
    end

    // Next state and output logic
    always @(*) begin
        // Default values (maintain current state)
        next_state = state;
        next_timer = timer;
        next_tx_grant = tx_grant;
        next_backoff_attempts = backoff_attempts;
        next_backoff_time = backoff_time;
        next_carrier_sense = carrier_sense;
        next_collision_detected = collision_detected;
        
        case (state)
            IDLE: begin
                if (tx_request) begin
                    next_state = SENSE;
                    next_carrier_sense = 1'b0;
                    next_collision_detected = 1'b0;
                end
            end
            
            SENSE: begin
                if (rx_active) begin
                    next_carrier_sense = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_carrier_sense = 1'b0;
                    next_tx_grant = 1'b1;
                    next_state = TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                if (rx_active) begin
                    next_collision_detected = 1'b1;
                    next_tx_grant = 1'b0;
                    next_backoff_attempts = (backoff_attempts_buf1 < 15) ? backoff_attempts_buf1 + 1'b1 : backoff_attempts_buf1;
                    next_state = COLLISION;
                end else if (tx_complete) begin
                    next_tx_grant = 1'b0;
                    next_backoff_attempts = 4'd0;
                    next_state = IFG;
                    next_timer = IFG_TIME;
                end
            end
            
            COLLISION: begin
                // Use pre-calculated backoff time
                next_backoff_time = backoff_calc_result;
                next_state = BACKOFF;
                next_timer = backoff_calc_result;
                next_collision_detected = 1'b0;
            end
            
            BACKOFF: begin
                if (timer > 0) begin
                    next_timer = timer - 16'd1;
                end else begin
                    next_state = IDLE;
                end
            end
            
            IFG: begin
                if (timer > 0) begin
                    next_timer = timer - 16'd1;
                end else begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule