//SystemVerilog
module eth_backoff_timer (
    input wire clk,
    input wire rst_n,
    input wire start_backoff,
    input wire [3:0] collision_count,
    output reg backoff_active,
    output reg backoff_complete,
    output reg [15:0] backoff_time,
    output reg [15:0] current_time
);
    // Constants
    localparam SLOT_TIME = 16'd512; // 512 bit times = 64 bytes
    localparam INIT_SEED = 8'h45;   // Arbitrary initial seed
    
    // LFSR and collision processing registers
    reg [7:0] random_seed;
    wire [7:0] lfsr_tap = random_seed[7] ^ random_seed[5] ^ random_seed[4] ^ random_seed[3];
    wire [7:0] lfsr_next = {random_seed[6:0], lfsr_tap};
    
    // Moved combinational logic before registers (forward retiming)
    wire collision_count_ge10 = (collision_count >= 4'd10);
    wire [15:0] max_slots_calc = collision_count_ge10 ? 16'd1023 : ((16'd1 << collision_count) - 16'd1);
    
    // Pipelined registers after combinational logic
    reg start_backoff_stage1, start_backoff_stage2;
    reg [15:0] max_slots_stage1, max_slots_stage2;
    reg [7:0] random_seed_stage1, random_seed_stage2;
    reg [15:0] backoff_time_calc;
    
    // Backoff control signals
    reg backoff_active_next;
    reg backoff_complete_next;
    reg [15:0] current_time_next;
    reg [15:0] backoff_time_next;
    
    // Backoff counting logic
    wire backoff_complete_condition = (current_time >= backoff_time) && backoff_active;
    
    // Pipeline stage 1: LFSR update and max slots calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            random_seed <= INIT_SEED;
            start_backoff_stage1 <= 1'b0;
            max_slots_stage1 <= 16'd0;
        end else begin
            random_seed <= lfsr_next;
            start_backoff_stage1 <= start_backoff;
            
            // Calculate max_slots directly from input combinational logic
            if (start_backoff) begin
                max_slots_stage1 <= max_slots_calc;
            end
        end
    end
    
    // Pipeline stage 2: Prepare for backoff time calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_backoff_stage2 <= 1'b0;
            random_seed_stage1 <= INIT_SEED;
            max_slots_stage2 <= 16'd0;
        end else begin
            start_backoff_stage2 <= start_backoff_stage1;
            random_seed_stage1 <= random_seed;
            max_slots_stage2 <= max_slots_stage1;
        end
    end
    
    // Pipeline stage 3: Backoff time calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            random_seed_stage2 <= INIT_SEED;
            backoff_time_calc <= 16'd0;
        end else begin
            random_seed_stage2 <= random_seed_stage1;
            
            // Calculate backoff time based on random seed and max slots
            if (start_backoff_stage2) begin
                backoff_time_calc <= (random_seed_stage2 % (max_slots_stage2 + 16'd1)) * SLOT_TIME;
            end
        end
    end
    
    // Pipeline stage 4: Output processing and backoff counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backoff_active <= 1'b0;
            backoff_complete <= 1'b0;
            backoff_time <= 16'd0;
            current_time <= 16'd0;
            backoff_active_next <= 1'b0;
            backoff_complete_next <= 1'b0;
            current_time_next <= 16'd0;
            backoff_time_next <= 16'd0;
        end else begin
            // Default values
            backoff_complete <= backoff_complete_next;
            backoff_complete_next <= 1'b0;
            
            // Update outputs from pipeline
            if (start_backoff_stage2) begin
                backoff_time_next <= backoff_time_calc;
                current_time_next <= 16'd0;
                backoff_active_next <= 1'b1;
            end
            
            // Apply changes to output registers
            backoff_active <= backoff_active_next;
            backoff_time <= backoff_time_next;
            current_time <= current_time_next;
            
            // Count up during backoff in the last stage
            if (backoff_active_next) begin
                if (current_time_next < backoff_time_next) begin
                    current_time_next <= current_time_next + 16'd1;
                end else begin
                    backoff_active_next <= 1'b0;
                    backoff_complete_next <= 1'b1;
                end
            end
        end
    end
endmodule