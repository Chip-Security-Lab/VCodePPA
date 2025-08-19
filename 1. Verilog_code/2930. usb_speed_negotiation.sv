module usb_speed_negotiation(
    input wire clk,
    input wire rst_n,
    input wire bus_reset_detected,
    input wire chirp_k_detected,
    input wire chirp_j_detected,
    input wire high_speed_supported,
    input wire negotiation_enable,
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
    
    reg [15:0] chirp_counter;
    reg [3:0] handshake_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_state <= IDLE;
            device_speed <= FULL_SPEED;
            negotiation_complete <= 1'b0;
            dp_out <= 1'b1;  // J state (full-speed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b1;
            dm_oe <= 1'b1;
            chirp_counter <= 16'd0;
            handshake_count <= 4'd0;
        end else begin
            case (speed_state)
                IDLE: begin
                    negotiation_complete <= 1'b0;
                    if (bus_reset_detected) begin
                        speed_state <= RESET;
                        chirp_counter <= 16'd0;
                    end
                end
                RESET: begin
                    if (!bus_reset_detected) begin
                        if (high_speed_supported && negotiation_enable) begin
                            speed_state <= CHIRP_K;
                            dp_out <= 1'b0;  // K state
                            dm_out <= 1'b1;
                            dp_oe <= 1'b1;
                            dm_oe <= 1'b1;
                            chirp_counter <= 16'd0;
                            handshake_count <= 4'd0;
                        end else begin
                            speed_state <= SPEED_SELECTED;
                            device_speed <= FULL_SPEED;
                            negotiation_complete <= 1'b1;
                        end
                    end
                end
                CHIRP_K: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= 16'd7500) begin  // ~156.25µs K chirp
                        speed_state <= DETECT_HANDSHAKE;
                        dp_oe <= 1'b0;
                        dm_oe <= 1'b0;
                        chirp_counter <= 16'd0;
                    end
                end
                DETECT_HANDSHAKE: begin
                    if (chirp_j_detected && handshake_count < 4'd15)
                        handshake_count <= handshake_count + 4'd1;
                    
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= 16'd20000) begin  // Timeout waiting for handshake
                        speed_state <= SPEED_SELECTED;
                        device_speed <= (handshake_count >= 4'd3) ? HIGH_SPEED : FULL_SPEED;
                        negotiation_complete <= 1'b1;
                    end
                end
                SPEED_SELECTED: begin
                    // Set line state based on negotiated speed
                    if (device_speed == HIGH_SPEED) begin
                        // High speed idle is SE0
                        dp_out <= 1'b0;
                        dm_out <= 1'b0;
                    end else begin
                        // Full speed idle is J state
                        dp_out <= 1'b1;
                        dm_out <= 1'b0;
                    end
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    
                    // Stay in this state until next reset/negotiation
                    if (bus_reset_detected) begin
                        speed_state <= RESET;
                        negotiation_complete <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule