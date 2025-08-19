//SystemVerilog
module usb_hs_negotiation(
    input wire clk,
    input wire rst_n,
    input wire chirp_start,
    input wire dp_in,
    input wire dm_in,
    output reg dp_out,
    output reg dm_out,
    output reg dp_oe,
    output reg dm_oe,
    output reg hs_detected,
    output reg [2:0] chirp_state,
    output reg [1:0] speed_status
);
    // Chirp state machine states
    localparam IDLE      = 3'd0;
    localparam K_CHIRP   = 3'd1;
    localparam J_DETECT  = 3'd2;
    localparam K_DETECT  = 3'd3;
    localparam HANDSHAKE = 3'd4;
    localparam COMPLETE  = 3'd5;
    
    // Speed status values
    localparam FULLSPEED = 2'd0;
    localparam HIGHSPEED = 2'd1;
    
    // Optimized counter with reduced bit width
    reg [15:0] chirp_counter;
    reg [2:0] kj_count;
    
    // Pipeline stage registers
    reg dp_in_stage1, dm_in_stage1;
    reg dp_in_stage2, dm_in_stage2;
    reg chirp_start_stage1, chirp_start_stage2;
    
    // K and J state detection pipeline
    wire k_state_stage1 = !dp_in_stage1 && dm_in_stage1;
    wire j_state_stage1 = dp_in_stage1 && !dm_in_stage1;
    
    reg k_state_stage2, j_state_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Decision stage signals
    reg [2:0] next_state_stage2;
    reg [15:0] next_counter_stage2;
    reg [2:0] next_kj_count_stage2;
    
    // Output stage signals
    reg dp_out_stage3, dm_out_stage3;
    reg dp_oe_stage3, dm_oe_stage3;
    reg hs_detected_stage3;
    reg [1:0] speed_status_stage3;
    
    // Timing constants
    localparam K_CHIRP_DURATION = 16'd7500;  // ~156.25µs for K chirp
    
    // Stage 1: Input Sampling and Preprocessing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_in_stage1 <= 1'b0;
            dm_in_stage1 <= 1'b0;
            chirp_start_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            dp_in_stage1 <= dp_in;
            dm_in_stage1 <= dm_in;
            chirp_start_stage1 <= chirp_start;
            valid_stage1 <= 1'b1;  // Always valid after reset
        end
    end
    
    // Stage 2: State Computation and Decision
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_in_stage2 <= 1'b0;
            dm_in_stage2 <= 1'b0;
            chirp_start_stage2 <= 1'b0;
            k_state_stage2 <= 1'b0;
            j_state_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            next_state_stage2 <= IDLE;
            next_counter_stage2 <= 16'd0;
            next_kj_count_stage2 <= 3'd0;
        end else if (valid_stage1) begin
            dp_in_stage2 <= dp_in_stage1;
            dm_in_stage2 <= dm_in_stage1;
            chirp_start_stage2 <= chirp_start_stage1;
            k_state_stage2 <= k_state_stage1;
            j_state_stage2 <= j_state_stage1;
            valid_stage2 <= valid_stage1;
            
            // State decision logic
            case (chirp_state)
                IDLE: begin
                    if (chirp_start_stage1) begin
                        next_state_stage2 <= K_CHIRP;
                        next_counter_stage2 <= 16'd0;
                        next_kj_count_stage2 <= 3'd0;
                    end else begin
                        next_state_stage2 <= IDLE;
                        next_counter_stage2 <= 16'd0;
                        next_kj_count_stage2 <= 3'd0;
                    end
                end
                
                K_CHIRP: begin
                    next_counter_stage2 <= chirp_counter + 16'd1;
                    
                    if (chirp_counter == K_CHIRP_DURATION - 16'd1) begin
                        next_state_stage2 <= J_DETECT;
                        next_counter_stage2 <= 16'd0;
                        next_kj_count_stage2 <= 3'd0;
                    end else begin
                        next_state_stage2 <= K_CHIRP;
                        next_kj_count_stage2 <= kj_count;
                    end
                end
                
                J_DETECT: begin
                    // Additional states would go here
                    next_state_stage2 <= J_DETECT;  // Simplified for example
                    next_counter_stage2 <= chirp_counter;
                    next_kj_count_stage2 <= kj_count;
                end
                
                default: begin
                    next_state_stage2 <= IDLE;
                    next_counter_stage2 <= 16'd0;
                    next_kj_count_stage2 <= 3'd0;
                end
            endcase
        end
    end
    
    // Stage 3: Output Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_state <= IDLE;
            speed_status <= FULLSPEED;
            hs_detected <= 1'b0;
            dp_out <= 1'b1;  // J state (fullspeed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
            chirp_counter <= 16'd0;
            kj_count <= 3'd0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // Update state and counters
            chirp_state <= next_state_stage2;
            chirp_counter <= next_counter_stage2;
            kj_count <= next_kj_count_stage2;
            valid_stage3 <= valid_stage2;
            
            // Generate outputs based on next state
            case (next_state_stage2)
                IDLE: begin
                    speed_status <= FULLSPEED;
                    hs_detected <= 1'b0;
                    dp_out <= 1'b1;  // J state (fullspeed idle)
                    dm_out <= 1'b0;
                    dp_oe <= 1'b0;
                    dm_oe <= 1'b0;
                end
                
                K_CHIRP: begin
                    dp_out <= 1'b0;  // K state chirp
                    dm_out <= 1'b1;
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                end
                
                J_DETECT: begin
                    dp_oe <= 1'b0;
                    dm_oe <= 1'b0;
                    // Additional output logic would go here
                end
                
                default: begin
                    // Safe defaults
                    dp_out <= 1'b1;
                    dm_out <= 1'b0;
                    dp_oe <= 1'b0;
                    dm_oe <= 1'b0;
                end
            endcase
        end
    end

endmodule