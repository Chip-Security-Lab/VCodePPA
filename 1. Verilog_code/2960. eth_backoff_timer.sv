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
    reg [15:0] slot_time;
    reg [7:0] random_seed;
    reg [15:0] max_slots;
    
    // Use a linear-feedback shift register for pseudo-random number generation
    function [7:0] lfsr_next;
        input [7:0] current;
        begin
            lfsr_next = {current[6:0], current[7] ^ current[5] ^ current[4] ^ current[3]};
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backoff_active <= 1'b0;
            backoff_complete <= 1'b0;
            backoff_time <= 16'd0;
            current_time <= 16'd0;
            slot_time <= 16'd512; // 512 bit times = 64 bytes
            random_seed <= 8'h45; // Arbitrary initial seed
            max_slots <= 16'd0;
        end else begin
            backoff_complete <= 1'b0;
            
            // Update random seed
            random_seed <= lfsr_next(random_seed);
            
            if (start_backoff) begin
                // Calculate maximum slots based on collision count (2^k - 1)
                if (collision_count >= 10) begin
                    max_slots <= 16'd1023; // 2^10 - 1
                end else begin
                    max_slots <= (16'd1 << collision_count) - 16'd1;
                end
                
                // Select random number of slots for backoff
                backoff_time <= (random_seed[7:0] % (max_slots + 1)) * slot_time;
                current_time <= 16'd0;
                backoff_active <= 1'b1;
            end else if (backoff_active) begin
                // Count up during backoff
                if (current_time < backoff_time) begin
                    current_time <= current_time + 16'd1;
                end else begin
                    backoff_active <= 1'b0;
                    backoff_complete <= 1'b1;
                end
            end
        end
    end
endmodule