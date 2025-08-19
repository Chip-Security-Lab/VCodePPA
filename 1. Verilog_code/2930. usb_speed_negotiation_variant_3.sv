//SystemVerilog
module usb_speed_negotiation(
    input wire clk,
    input wire rst_n,
    
    // Input interface with valid-ready handshake
    input wire in_valid,
    output reg in_ready,
    input wire bus_reset_detected,
    input wire chirp_k_detected,
    input wire chirp_j_detected,
    input wire high_speed_supported,
    input wire negotiation_enable,
    
    // Output interface with valid-ready handshake
    output reg out_valid,
    input wire out_ready,
    output reg dp_out,
    output reg dm_out,
    output reg dp_oe,
    output reg dm_oe,
    output reg [1:0] device_speed,
    output reg negotiation_complete,
    output reg [2:0] speed_state
);
    // Speed definitions
    localparam FULL_SPEED = 2'b00;
    localparam HIGH_SPEED = 2'b01;
    localparam LOW_SPEED = 2'b10;
    
    // State machine states
    localparam IDLE = 3'd0;
    localparam RESET = 3'd1;
    localparam CHIRP_K = 3'd2;
    localparam DETECT_HANDSHAKE = 3'd3;
    localparam SPEED_SELECTED = 3'd4;
    localparam WAIT_OUTPUT_READY = 3'd5;
    localparam WAIT_INPUT_VALID = 3'd6;
    
    reg [15:0] chirp_counter;
    reg [3:0] handshake_count;
    
    // Constants for timing comparison
    localparam CHIRP_K_DURATION = 16'd7500;   // ~156.25µs K chirp
    localparam HANDSHAKE_TIMEOUT = 16'd20000; // Timeout waiting for handshake
    localparam MIN_HANDSHAKES = 4'd3;         // Minimum handshakes for high-speed
    
    // Control signals for line state
    reg enter_chirp_k, exit_detect_handshake;
    reg use_high_speed_idle;
    
    // Input data registers to hold values when handshaking
    reg bus_reset_detected_reg;
    reg chirp_k_detected_reg;
    reg chirp_j_detected_reg;
    reg high_speed_supported_reg;
    reg negotiation_enable_reg;
    
    // Output data registers
    reg dp_out_next, dm_out_next;
    reg dp_oe_next, dm_oe_next;
    reg [1:0] device_speed_next;
    reg negotiation_complete_next;
    
    // Line state logic
    always @(*) begin
        // Default idle state (Full-speed J state)
        dp_out_next = 1'b1;
        dm_out_next = 1'b0;
        
        if (speed_state == CHIRP_K) begin
            // K state
            dp_out_next = 1'b0;
            dm_out_next = 1'b1;
        end else if (use_high_speed_idle) begin
            // High speed idle (SE0)
            dp_out_next = 1'b0;
            dm_out_next = 1'b0;
        end
    end
    
    // Input handshaking logic - capture input when valid and ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_reset_detected_reg <= 1'b0;
            chirp_k_detected_reg <= 1'b0;
            chirp_j_detected_reg <= 1'b0;
            high_speed_supported_reg <= 1'b0;
            negotiation_enable_reg <= 1'b0;
            in_ready <= 1'b1;
        end else begin
            // Capture input data when valid and ready
            if (in_valid && in_ready) begin
                bus_reset_detected_reg <= bus_reset_detected;
                chirp_k_detected_reg <= chirp_k_detected;
                chirp_j_detected_reg <= chirp_j_detected;
                high_speed_supported_reg <= high_speed_supported;
                negotiation_enable_reg <= negotiation_enable;
                
                // Deassert ready after capturing data
                in_ready <= 1'b0;
            end
            
            // Re-assert ready when entering WAIT_INPUT_VALID state
            if (speed_state == WAIT_INPUT_VALID) begin
                in_ready <= 1'b1;
            end
        end
    end
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_state <= IDLE;
            device_speed <= FULL_SPEED;
            device_speed_next <= FULL_SPEED;
            negotiation_complete <= 1'b0;
            negotiation_complete_next <= 1'b0;
            dp_oe <= 1'b1;
            dm_oe <= 1'b1;
            dp_oe_next <= 1'b1;
            dm_oe_next <= 1'b1;
            dp_out <= 1'b1;
            dm_out <= 1'b0;
            chirp_counter <= 16'd0;
            handshake_count <= 4'd0;
            use_high_speed_idle <= 1'b0;
            enter_chirp_k <= 1'b0;
            exit_detect_handshake <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            // Default values
            enter_chirp_k <= 1'b0;
            exit_detect_handshake <= 1'b0;
            
            case (speed_state)
                IDLE: begin
                    negotiation_complete_next <= 1'b0;
                    if (in_valid && in_ready) begin
                        if (bus_reset_detected) begin
                            speed_state <= RESET;
                            chirp_counter <= 16'd0;
                        end
                    end else begin
                        // Wait for valid input
                        speed_state <= WAIT_INPUT_VALID;
                    end
                end
                
                WAIT_INPUT_VALID: begin
                    if (in_valid && in_ready) begin
                        speed_state <= IDLE;
                    end
                end
                
                RESET: begin
                    if (!bus_reset_detected_reg) begin
                        if (high_speed_supported_reg && negotiation_enable_reg) begin
                            speed_state <= CHIRP_K;
                            enter_chirp_k <= 1'b1;
                        end else begin
                            speed_state <= SPEED_SELECTED;
                            device_speed_next <= FULL_SPEED;
                            negotiation_complete_next <= 1'b1;
                            out_valid <= 1'b1;
                        end
                    end
                end
                
                CHIRP_K: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= CHIRP_K_DURATION) begin
                        speed_state <= DETECT_HANDSHAKE;
                        dp_oe_next <= 1'b0;
                        dm_oe_next <= 1'b0;
                        chirp_counter <= 16'd0;
                    end
                end
                
                DETECT_HANDSHAKE: begin
                    // Increment counter only on edge detection to avoid multiple counts
                    if (chirp_j_detected_reg && chirp_counter[2:0] == 3'b000 && handshake_count < 4'd15)
                        handshake_count <= handshake_count + 4'd1;
                    
                    chirp_counter <= chirp_counter + 16'd1;
                    
                    if (chirp_counter >= HANDSHAKE_TIMEOUT) begin
                        exit_detect_handshake <= 1'b1;
                    end
                end
                
                SPEED_SELECTED: begin
                    // Set line state based on negotiated speed
                    dp_oe_next <= 1'b1;
                    dm_oe_next <= 1'b1;
                    
                    // Prepare output data and wait for ready
                    out_valid <= 1'b1;
                    
                    if (out_valid && out_ready) begin
                        // Transfer completed, update outputs
                        dp_out <= dp_out_next;
                        dm_out <= dm_out_next;
                        dp_oe <= dp_oe_next;
                        dm_oe <= dm_oe_next;
                        device_speed <= device_speed_next;
                        negotiation_complete <= negotiation_complete_next;
                        speed_state <= WAIT_INPUT_VALID;
                        out_valid <= 1'b0;
                    end else if (out_valid && !out_ready) begin
                        // Wait for output to be ready
                        speed_state <= WAIT_OUTPUT_READY;
                    end
                    
                    // Handle new reset/negotiation
                    if (in_valid && in_ready && bus_reset_detected) begin
                        speed_state <= RESET;
                        negotiation_complete_next <= 1'b0;
                        out_valid <= 1'b0;
                    end
                end
                
                WAIT_OUTPUT_READY: begin
                    if (out_ready) begin
                        // Output has been consumed
                        dp_out <= dp_out_next;
                        dm_out <= dm_out_next;
                        dp_oe <= dp_oe_next;
                        dm_oe <= dm_oe_next;
                        device_speed <= device_speed_next;
                        negotiation_complete <= negotiation_complete_next;
                        speed_state <= WAIT_INPUT_VALID;
                        out_valid <= 1'b0;
                    end
                end
            endcase
            
            // Handle transitions that affect multiple signals
            if (enter_chirp_k) begin
                dp_oe_next <= 1'b1;
                dm_oe_next <= 1'b1;
                chirp_counter <= 16'd0;
                handshake_count <= 4'd0;
            end
            
            if (exit_detect_handshake) begin
                speed_state <= SPEED_SELECTED;
                use_high_speed_idle <= (handshake_count >= MIN_HANDSHAKES);
                device_speed_next <= (handshake_count >= MIN_HANDSHAKES) ? HIGH_SPEED : FULL_SPEED;
                negotiation_complete_next <= 1'b1;
                out_valid <= 1'b1;
            end
            
            // Apply output changes directly in appropriate states
            if (speed_state == CHIRP_K || speed_state == DETECT_HANDSHAKE) begin
                dp_out <= dp_out_next;
                dm_out <= dm_out_next;
                dp_oe <= dp_oe_next;
                dm_oe <= dm_oe_next;
            end
        end
    end
endmodule