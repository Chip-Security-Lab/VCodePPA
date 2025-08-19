//SystemVerilog
module eth_half_duplex_controller (
    input wire clk,
    input wire rst_n,
    
    // MAC layer interface with Valid-Ready handshake
    input wire tx_request_valid,
    output wire tx_request_ready,
    input wire [15:0] tx_data,  // Added data signal
    
    output wire tx_grant_valid,
    input wire tx_grant_ready,
    
    input wire tx_complete_valid,
    output wire tx_complete_ready,
    
    input wire rx_active_valid,
    output wire rx_active_ready,
    
    // Status signals with Valid-Ready handshake
    output wire [3:0] backoff_attempts,
    output wire [15:0] backoff_time,
    output wire status_valid,
    input wire status_ready,
    output wire carrier_sense,
    output wire collision_detected
);
    // State definitions using one-hot encoding for better optimization
    localparam [5:0] IDLE     = 6'b000001, 
                     SENSE    = 6'b000010, 
                     TRANSMIT = 6'b000100,
                     COLLISION= 6'b001000, 
                     BACKOFF  = 6'b010000, 
                     IFG      = 6'b100000;
    
    // Interframe gap time constant
    localparam IFG_TIME = 16'd12; // 12 byte times
    localparam MAX_BACKOFF_ATTEMPTS = 4'd15;
    localparam MAX_BACKOFF_WINDOW = 16'd1023; // 2^10 - 1
    
    // Internal registers
    reg [5:0] state, next_state;
    reg [15:0] timer, next_timer;
    reg tx_grant_r, next_tx_grant;
    reg [3:0] backoff_attempts_r, next_backoff_attempts;
    reg [15:0] backoff_time_r, next_backoff_time;
    reg carrier_sense_r, next_carrier_sense;
    reg collision_detected_r, next_collision_detected;
    
    // Handshake control registers
    reg status_valid_r, next_status_valid;
    reg tx_request_ready_r, next_tx_request_ready;
    reg tx_complete_ready_r, next_tx_complete_ready;
    reg rx_active_ready_r, next_rx_active_ready;
    
    // Capture signals when valid & ready
    wire tx_request = tx_request_valid & tx_request_ready_r;
    wire tx_complete = tx_complete_valid & tx_complete_ready_r;
    wire rx_active = rx_active_valid & rx_active_ready_r;
    wire status_accepted = status_valid_r & status_ready;
    wire tx_grant_accepted = tx_grant_valid & tx_grant_ready;
    
    // Output assignments
    assign tx_request_ready = tx_request_ready_r;
    assign tx_complete_ready = tx_complete_ready_r;
    assign rx_active_ready = rx_active_ready_r;
    assign tx_grant_valid = tx_grant_r;
    assign status_valid = status_valid_r;
    assign backoff_attempts = backoff_attempts_r;
    assign backoff_time = backoff_time_r;
    assign carrier_sense = carrier_sense_r;
    assign collision_detected = collision_detected_r;
    
    // State transition and output logic
    always @(*) begin
        // Default: maintain current values
        next_state = state;
        next_timer = timer;
        next_tx_grant = tx_grant_r;
        next_backoff_attempts = backoff_attempts_r;
        next_backoff_time = backoff_time_r;
        next_carrier_sense = carrier_sense_r;
        next_collision_detected = collision_detected_r;
        
        // Handshake defaults
        next_status_valid = status_valid_r;
        next_tx_request_ready = 1'b1;  // Default to accepting tx requests
        next_tx_complete_ready = 1'b1; // Default to accepting tx complete
        next_rx_active_ready = 1'b1;   // Default to accepting rx active signals
        
        case (state)
            IDLE: begin
                if (tx_request) begin
                    next_state = SENSE;
                    next_carrier_sense = 1'b0;
                    next_collision_detected = 1'b0;
                    next_status_valid = 1'b1; // Status changed
                end
                
                // Only accept new tx requests when idle
                next_tx_request_ready = 1'b1;
            end
            
            SENSE: begin
                // Simplified carrier sense check with handshake
                if (rx_active_valid) begin
                    next_carrier_sense = rx_active;
                    next_status_valid = 1'b1; // Status changed
                    
                    if (rx_active) begin
                        next_state = IDLE;
                    end else begin
                        next_tx_grant = 1'b1;
                        next_state = TRANSMIT;
                    end
                end
                
                // Don't accept new tx requests during sensing
                next_tx_request_ready = 1'b0;
            end
            
            TRANSMIT: begin
                // Optimized collision detection and tx completion check
                if (rx_active) begin
                    next_collision_detected = 1'b1;
                    next_tx_grant = 1'b0;
                    next_state = COLLISION;
                    next_status_valid = 1'b1; // Status changed
                    
                    // More efficient backoff attempts tracking
                    next_backoff_attempts = (backoff_attempts_r < MAX_BACKOFF_ATTEMPTS) ? 
                                           backoff_attempts_r + 1'b1 : backoff_attempts_r;
                end else if (tx_complete) begin
                    next_tx_grant = 1'b0;
                    next_backoff_attempts = 4'd0;
                    next_state = IFG;
                    next_timer = IFG_TIME;
                    next_status_valid = 1'b1; // Status changed
                end
                
                // Don't accept new tx requests during transmission
                next_tx_request_ready = 1'b0;
            end
            
            COLLISION: begin
                // Optimized backoff calculation with range check
                next_backoff_time = (backoff_attempts_r <= 10) ? 
                                   ((16'd1 << backoff_attempts_r) - 16'd1) : 
                                   MAX_BACKOFF_WINDOW;
                next_state = BACKOFF;
                next_timer = next_backoff_time; // Use next_backoff_time directly
                next_collision_detected = 1'b0;
                next_status_valid = 1'b1; // Status changed
                
                // Don't accept new tx requests during collision handling
                next_tx_request_ready = 1'b0;
            end
            
            BACKOFF, IFG: begin
                // Merged timer decrement logic for BACKOFF and IFG states
                if (|timer) begin // Faster check than timer > 0
                    next_timer = timer - 16'd1;
                end else begin
                    next_state = IDLE;
                    next_status_valid = 1'b1; // Status changed
                end
                
                // Don't accept new tx requests during backoff/IFG
                next_tx_request_ready = 1'b0;
            end
            
            default: begin
                next_state = IDLE;
                next_tx_request_ready = 1'b1;
            end
        endcase
        
        // Clear status valid once status is accepted
        if (status_accepted) begin
            next_status_valid = 1'b0;
        end
        
        // Clear tx_grant once accepted
        if (tx_grant_accepted) begin
            next_tx_grant = 1'b0;
        end
    end
    
    // Sequential logic for state and output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_grant_r <= 1'b0;
            backoff_attempts_r <= 4'd0;
            backoff_time_r <= 16'd0;
            carrier_sense_r <= 1'b0;
            collision_detected_r <= 1'b0;
            timer <= 16'd0;
            
            // Reset handshake signals
            status_valid_r <= 1'b0;
            tx_request_ready_r <= 1'b1;
            tx_complete_ready_r <= 1'b1;
            rx_active_ready_r <= 1'b1;
        end else begin
            state <= next_state;
            timer <= next_timer;
            tx_grant_r <= next_tx_grant;
            backoff_attempts_r <= next_backoff_attempts;
            backoff_time_r <= next_backoff_time;
            carrier_sense_r <= next_carrier_sense;
            collision_detected_r <= next_collision_detected;
            
            // Update handshake signals
            status_valid_r <= next_status_valid;
            tx_request_ready_r <= next_tx_request_ready;
            tx_complete_ready_r <= next_tx_complete_ready;
            rx_active_ready_r <= next_rx_active_ready;
        end
    end
endmodule