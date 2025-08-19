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
    reg [15:0] slot_time;
    reg [7:0] random_seed;
    reg [15:0] max_slots;
    
    // 移动到组合逻辑后的中间信号
    reg [15:0] next_max_slots;
    reg [15:0] next_backoff_time;
    reg [7:0] next_random_seed;
    reg next_backoff_active;
    reg next_backoff_complete;
    reg [15:0] next_current_time;
    
    // Use a linear-feedback shift register for pseudo-random number generation
    function [7:0] lfsr_next;
        input [7:0] current;
        begin
            lfsr_next = {current[6:0], current[7] ^ current[5] ^ current[4] ^ current[3]};
        end
    endfunction
    
    // 前向重定时：将组合逻辑计算移到寄存器前
    always @(*) begin
        // 默认值保持不变
        next_max_slots = max_slots;
        next_random_seed = lfsr_next(random_seed);
        next_backoff_time = backoff_time;
        next_backoff_active = backoff_active;
        next_backoff_complete = 1'b0; // 每个周期默认为0
        next_current_time = current_time;
        
        if (start_backoff) begin
            // Calculate maximum slots based on collision count (2^k - 1)
            if (collision_count >= 10) begin
                next_max_slots = 16'd1023; // 2^10 - 1
            end else begin
                next_max_slots = (16'd1 << collision_count) - 16'd1;
            end
            
            // Select random number of slots for backoff
            next_backoff_time = (next_random_seed[7:0] % (next_max_slots + 1)) * slot_time;
            next_current_time = 16'd0;
            next_backoff_active = 1'b1;
        end else if (backoff_active) begin
            // Count up during backoff
            if (current_time < backoff_time) begin
                next_current_time = current_time + 16'd1;
            end else begin
                next_backoff_active = 1'b0;
                next_backoff_complete = 1'b1;
            end
        end
    end
    
    // 寄存器更新
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
            // 更新寄存器
            backoff_active <= next_backoff_active;
            backoff_complete <= next_backoff_complete;
            backoff_time <= next_backoff_time;
            current_time <= next_current_time;
            random_seed <= next_random_seed;
            max_slots <= next_max_slots;
        end
    end
endmodule