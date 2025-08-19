//SystemVerilog
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
    
    // State machine states with Gray code encoding
    localparam IDLE = 3'b000;             // 0 -> 000
    localparam RESET = 3'b001;            // 1 -> 001
    localparam CHIRP_K = 3'b011;          // 2 -> 011
    localparam DETECT_HANDSHAKE = 3'b010; // 3 -> 010
    localparam SPEED_SELECTED = 3'b110;   // 4 -> 110
    
    reg [15:0] chirp_counter;
    reg [3:0] handshake_count;
    
    // Signals for Brent-Kung Adder
    wire [15:0] bk_sum;
    wire [15:0] next_chirp_counter;
    
    // Instantiate Brent-Kung Adder for chirp_counter
    brent_kung_adder #(
        .WIDTH(16)
    ) chirp_counter_adder (
        .a(chirp_counter),
        .b(16'd1),
        .sum(bk_sum),
        .cout()
    );
    
    assign next_chirp_counter = bk_sum;
    
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
                    chirp_counter <= next_chirp_counter;
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
                    
                    chirp_counter <= next_chirp_counter;
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
                default: begin
                    speed_state <= IDLE;
                end
            endcase
        end
    end
endmodule

// Brent-Kung adder module (prefixed propagate-generate parallel prefix adder)
module brent_kung_adder #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] c;
    
    // Stage 1: Generate initial propagate and generate signals
    assign g = a & b;                   // Generate: g_i = a_i & b_i
    assign p = a ^ b;                   // Propagate: p_i = a_i ^ b_i
    
    // Group propagate-generate signals for tree-based computation
    wire [WIDTH-1:0] group_g;
    wire [WIDTH-1:0] group_p;
    
    // Initial values
    assign group_g[0] = g[0];
    assign group_p[0] = p[0];
    
    // First level of tree (pairs)
    genvar i, j, k;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin: level1
            assign group_g[i] = g[i];
            assign group_p[i] = p[i];
        end
    endgenerate
    
    // Tree-based computation for carry generation
    // Level 2: Compute for every 2^1 distance
    wire [WIDTH-1:0] level2_g, level2_p;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_level2
            if (i <= 0) begin
                assign level2_g[i] = group_g[i];
                assign level2_p[i] = group_p[i];
            end else if (i % 2 == 1) begin
                assign level2_g[i] = group_g[i] | (group_p[i] & group_g[i-1]);
                assign level2_p[i] = group_p[i] & group_p[i-1];
            end else begin
                assign level2_g[i] = group_g[i];
                assign level2_p[i] = group_p[i];
            end
        end
    endgenerate
    
    // Level 3: Compute for every 2^2 distance
    wire [WIDTH-1:0] level3_g, level3_p;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_level3
            if (i <= 1) begin
                assign level3_g[i] = level2_g[i];
                assign level3_p[i] = level2_p[i];
            end else if (i % 4 == 3) begin
                assign level3_g[i] = level2_g[i] | (level2_p[i] & level2_g[i-2]);
                assign level3_p[i] = level2_p[i] & level2_p[i-2];
            end else begin
                assign level3_g[i] = level2_g[i];
                assign level3_p[i] = level2_p[i];
            end
        end
    endgenerate
    
    // Level 4: Compute for every 2^3 distance
    wire [WIDTH-1:0] level4_g, level4_p;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_level4
            if (i <= 3) begin
                assign level4_g[i] = level3_g[i];
                assign level4_p[i] = level3_p[i];
            end else if (i % 8 == 7) begin
                assign level4_g[i] = level3_g[i] | (level3_p[i] & level3_g[i-4]);
                assign level4_p[i] = level3_p[i] & level3_p[i-4];
            end else begin
                assign level4_g[i] = level3_g[i];
                assign level4_p[i] = level3_p[i];
            end
        end
    endgenerate
    
    // Level 5: Final level for 16-bit operation (2^4)
    wire [WIDTH-1:0] level5_g, level5_p;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_level5
            if (i <= 7) begin
                assign level5_g[i] = level4_g[i];
                assign level5_p[i] = level4_p[i];
            end else if (i % 16 == 15) begin
                assign level5_g[i] = level4_g[i] | (level4_p[i] & level4_g[i-8]);
                assign level5_p[i] = level4_p[i] & level4_p[i-8];
            end else begin
                assign level5_g[i] = level4_g[i];
                assign level5_p[i] = level4_p[i];
            end
        end
    endgenerate
    
    // Inverse tree to compute all carries
    wire [WIDTH:0] carries;
    assign carries[0] = 1'b0; // No carry-in
    
    // Generate first carries from the prefix tree
    generate
        // First group of carries from prefix nodes
        assign carries[1] = level5_g[0]; // Direct from level 5
        
        // Even positions for 2nd level of post-processing
        for (i = 2; i < WIDTH; i = i + 2) begin: even_carries
            assign carries[i] = level5_g[i-1] | (level5_p[i-1] & carries[i-1]);
        end
        
        // Odd positions (except 1) for post-processing
        for (i = 3; i <= WIDTH; i = i + 2) begin: odd_carries
            assign carries[i] = level5_g[i-1] | (level5_p[i-1] & carries[i-1]);
        end
    endgenerate
    
    // Sum calculation
    assign sum = p ^ carries[WIDTH-1:0];
    assign cout = carries[WIDTH];
endmodule