//SystemVerilog - IEEE 1364-2005
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
    
    // Counter incrementing signals
    wire [15:0] counter_next;
    wire [3:0] handshake_next;
    
    // Pipelined CLA signals - stage 1
    reg [15:0] counter_p_stage1;
    reg [16:0] counter_c_stage1_partial; // First-level carries
    
    // Pipelined CLA signals - stage 2
    reg [16:0] counter_c_stage2; // Final carries
    
    // Handshake counter pipelined signals
    reg [3:0] handshake_p_stage1;
    reg [4:0] handshake_c_stage1;
    
    // Generate and Propagate signals for chirp_counter
    wire [15:0] counter_p = chirp_counter;
    wire [15:0] counter_g = 16'd0; // Since we're adding 1, g=0 for all bits
    
    // Initial carry-in
    wire counter_c0 = 1'b1; // Initial carry-in is 1 for incrementing
    
    // Pipeline state signals
    reg bus_reset_detected_reg;
    reg chirp_j_detected_reg;
    reg [15:0] chirp_counter_cmp;
    reg [3:0] handshake_count_cmp;
    reg handshake_complete;
    reg timeout_detected;

    // First level carries (split into smaller blocks to reduce path delay)
    wire [3:0] counter_c_block0;
    wire [3:0] counter_c_block1;
    wire [3:0] counter_c_block2;
    wire [3:0] counter_c_block3;
    
    // First block (bits 0-3)
    assign counter_c_block0[0] = counter_p[0] & counter_c0;
    assign counter_c_block0[1] = counter_p[1] & counter_p[0] & counter_c0;
    assign counter_c_block0[2] = counter_p[2] & counter_p[1] & counter_p[0] & counter_c0;
    assign counter_c_block0[3] = counter_p[3] & counter_p[2] & counter_p[1] & counter_p[0] & counter_c0;
    
    // Second block (bits 4-7)
    assign counter_c_block1[0] = counter_p[4] & counter_c_stage1_partial[4];
    assign counter_c_block1[1] = counter_p[5] & counter_p[4] & counter_c_stage1_partial[4];
    assign counter_c_block1[2] = counter_p[6] & counter_p[5] & counter_p[4] & counter_c_stage1_partial[4];
    assign counter_c_block1[3] = counter_p[7] & counter_p[6] & counter_p[5] & counter_p[4] & counter_c_stage1_partial[4];
    
    // Third block (bits 8-11)
    assign counter_c_block2[0] = counter_p[8] & counter_c_stage1_partial[8];
    assign counter_c_block2[1] = counter_p[9] & counter_p[8] & counter_c_stage1_partial[8];
    assign counter_c_block2[2] = counter_p[10] & counter_p[9] & counter_p[8] & counter_c_stage1_partial[8];
    assign counter_c_block2[3] = counter_p[11] & counter_p[10] & counter_p[9] & counter_p[8] & counter_c_stage1_partial[8];
    
    // Fourth block (bits 12-15)
    assign counter_c_block3[0] = counter_p[12] & counter_c_stage1_partial[12];
    assign counter_c_block3[1] = counter_p[13] & counter_p[12] & counter_c_stage1_partial[12];
    assign counter_c_block3[2] = counter_p[14] & counter_p[13] & counter_p[12] & counter_c_stage1_partial[12];
    assign counter_c_block3[3] = counter_p[15] & counter_p[14] & counter_p[13] & counter_p[12] & counter_c_stage1_partial[12];
    
    // Sum computation using pipelined carries
    assign counter_next = counter_p_stage1 ^ counter_c_stage2[15:0];
    
    // Compute handshake_next using pipelined carries
    assign handshake_next = handshake_p_stage1 ^ handshake_c_stage1[3:0];

    // Pipelined carry generation - stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_p_stage1 <= 16'd0;
            counter_c_stage1_partial <= 17'd0;
        end else begin
            counter_p_stage1 <= counter_p;
            
            // First-level carries
            counter_c_stage1_partial[0] <= counter_c0;
            counter_c_stage1_partial[1] <= counter_c_block0[0] | counter_g[0];
            counter_c_stage1_partial[2] <= counter_c_block0[1] | counter_g[1] | (counter_p[1] & counter_g[0]);
            counter_c_stage1_partial[3] <= counter_c_block0[2] | counter_g[2] | 
                                           (counter_p[2] & counter_g[1]) | 
                                           (counter_p[2] & counter_p[1] & counter_g[0]);
            counter_c_stage1_partial[4] <= counter_c_block0[3] | counter_g[3] | 
                                           (counter_p[3] & counter_g[2]) | 
                                           (counter_p[3] & counter_p[2] & counter_g[1]) |
                                           (counter_p[3] & counter_p[2] & counter_p[1] & counter_g[0]);
            
            // Group carries for remaining blocks
            counter_c_stage1_partial[8] <= counter_c_stage1_partial[4];
            counter_c_stage1_partial[12] <= counter_c_stage1_partial[8];
            counter_c_stage1_partial[16] <= counter_c_stage1_partial[12];
        end
    end
    
    // Pipelined carry generation - stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_c_stage2 <= 17'd0;
        end else begin
            // Final carries computation
            counter_c_stage2[0] <= counter_c_stage1_partial[0];
            counter_c_stage2[1] <= counter_c_stage1_partial[1];
            counter_c_stage2[2] <= counter_c_stage1_partial[2];
            counter_c_stage2[3] <= counter_c_stage1_partial[3];
            counter_c_stage2[4] <= counter_c_stage1_partial[4];
            
            counter_c_stage2[5] <= counter_c_block1[0] | counter_g[4];
            counter_c_stage2[6] <= counter_c_block1[1] | counter_g[5] | (counter_p[5] & counter_g[4]);
            counter_c_stage2[7] <= counter_c_block1[2] | counter_g[6] | 
                                   (counter_p[6] & counter_g[5]) | 
                                   (counter_p[6] & counter_p[5] & counter_g[4]);
            counter_c_stage2[8] <= counter_c_block1[3] | counter_g[7] | 
                                   (counter_p[7] & counter_g[6]) | 
                                   (counter_p[7] & counter_p[6] & counter_g[5]) |
                                   (counter_p[7] & counter_p[6] & counter_p[5] & counter_g[4]);
            
            counter_c_stage2[9] <= counter_c_block2[0] | counter_g[8];
            counter_c_stage2[10] <= counter_c_block2[1] | counter_g[9] | (counter_p[9] & counter_g[8]);
            counter_c_stage2[11] <= counter_c_block2[2] | counter_g[10] | 
                                    (counter_p[10] & counter_g[9]) | 
                                    (counter_p[10] & counter_p[9] & counter_g[8]);
            counter_c_stage2[12] <= counter_c_block2[3] | counter_g[11] | 
                                    (counter_p[11] & counter_g[10]) | 
                                    (counter_p[11] & counter_p[10] & counter_g[9]) |
                                    (counter_p[11] & counter_p[10] & counter_p[9] & counter_g[8]);
            
            counter_c_stage2[13] <= counter_c_block3[0] | counter_g[12];
            counter_c_stage2[14] <= counter_c_block3[1] | counter_g[13] | (counter_p[13] & counter_g[12]);
            counter_c_stage2[15] <= counter_c_block3[2] | counter_g[14] | 
                                    (counter_p[14] & counter_g[13]) | 
                                    (counter_p[14] & counter_p[13] & counter_g[12]);
            counter_c_stage2[16] <= counter_c_block3[3] | counter_g[15] | 
                                    (counter_p[15] & counter_g[14]) | 
                                    (counter_p[15] & counter_p[14] & counter_g[13]) |
                                    (counter_p[15] & counter_p[14] & counter_p[13] & counter_g[12]);
        end
    end

    // Simplified pipelined handshake counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handshake_p_stage1 <= 4'd0;
            handshake_c_stage1 <= 5'd0;
        end else begin
            handshake_p_stage1 <= handshake_count;
            
            // Compute carries
            handshake_c_stage1[0] <= 1'b1; // Initial carry-in is 1 for incrementing
            handshake_c_stage1[1] <= handshake_count[0];
            handshake_c_stage1[2] <= handshake_count[1] & handshake_count[0];
            handshake_c_stage1[3] <= handshake_count[2] & handshake_count[1] & handshake_count[0];
            handshake_c_stage1[4] <= handshake_count[3] & handshake_count[2] & handshake_count[1] & handshake_count[0];
        end
    end
    
    // Pipeline input signals and pre-compute comparisons
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_reset_detected_reg <= 1'b0;
            chirp_j_detected_reg <= 1'b0;
            chirp_counter_cmp <= 16'd0;
            handshake_count_cmp <= 4'd0;
            handshake_complete <= 1'b0;
            timeout_detected <= 1'b0;
        end else begin
            bus_reset_detected_reg <= bus_reset_detected;
            chirp_j_detected_reg <= chirp_j_detected;
            
            // Pre-compute comparisons to reduce critical path
            chirp_counter_cmp <= chirp_counter;
            handshake_count_cmp <= handshake_count;
            
            // Pre-calculate comparison results
            handshake_complete <= (handshake_count_cmp >= 4'd3);
            timeout_detected <= (chirp_counter_cmp >= 16'd20000);
        end
    end
    
    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_state <= IDLE;
            negotiation_complete <= 1'b0;
        end else begin
            case (speed_state)
                IDLE: begin
                    negotiation_complete <= 1'b0;
                    if (bus_reset_detected_reg) begin
                        speed_state <= RESET;
                    end
                end
                
                RESET: begin
                    if (!bus_reset_detected_reg) begin
                        if (high_speed_supported && negotiation_enable) begin
                            speed_state <= CHIRP_K;
                        end else begin
                            speed_state <= SPEED_SELECTED;
                            negotiation_complete <= 1'b1;
                        end
                    end
                end
                
                CHIRP_K: begin
                    if (chirp_counter_cmp >= 16'd7500) begin  // ~156.25µs K chirp
                        speed_state <= DETECT_HANDSHAKE;
                    end
                end
                
                DETECT_HANDSHAKE: begin
                    if (timeout_detected) begin  // Timeout waiting for handshake
                        speed_state <= SPEED_SELECTED;
                        negotiation_complete <= 1'b1;
                    end
                end
                
                SPEED_SELECTED: begin
                    // Stay in this state until next reset/negotiation
                    if (bus_reset_detected_reg) begin
                        speed_state <= RESET;
                        negotiation_complete <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // Line state and counter control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_out <= 1'b1;  // J state (full-speed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b1;
            dm_oe <= 1'b1;
            chirp_counter <= 16'd0;
            handshake_count <= 4'd0;
            device_speed <= FULL_SPEED;
        end else begin
            case (speed_state)
                IDLE: begin
                    // Maintain J state (full-speed idle)
                    dp_out <= 1'b1;
                    dm_out <= 1'b0;
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    chirp_counter <= 16'd0;
                end
                
                RESET: begin
                    if (!bus_reset_detected_reg) begin
                        if (high_speed_supported && negotiation_enable) begin
                            chirp_counter <= 16'd0;
                            handshake_count <= 4'd0;
                        end else begin
                            device_speed <= FULL_SPEED;
                        end
                    end
                end
                
                CHIRP_K: begin
                    // Output K state for chirp
                    dp_out <= 1'b0;
                    dm_out <= 1'b1;
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    chirp_counter <= counter_next;
                    
                    if (chirp_counter_cmp >= 16'd7500) begin
                        dp_oe <= 1'b0;
                        dm_oe <= 1'b0;
                        chirp_counter <= 16'd0;
                    end
                end
                
                DETECT_HANDSHAKE: begin
                    // Detect host chirps
                    if (chirp_j_detected_reg && handshake_count_cmp < 4'd15)
                        handshake_count <= handshake_next;
                    
                    chirp_counter <= counter_next;
                    
                    if (timeout_detected) begin
                        device_speed <= handshake_complete ? HIGH_SPEED : FULL_SPEED;
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
                end
            endcase
        end
    end
endmodule