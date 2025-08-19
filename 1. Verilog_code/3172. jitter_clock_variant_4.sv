//SystemVerilog
module jitter_clock(
    input clk_in,
    input rst,
    input [2:0] jitter_amount,
    input jitter_en,
    output reg clk_out
);
    reg [4:0] counter;
    reg [4:0] counter_buf1, counter_buf2;  // Buffer registers for counter
    reg [2:0] jitter;
    reg d0, d0_buf1, d0_buf2;  // Buffer registers for comparison result
    
    // Distribute high fanout signals using buffer registers
    always @(posedge clk_in) begin
        counter_buf1 <= counter;
        counter_buf2 <= counter;
        d0_buf1 <= d0;
        d0_buf2 <= d0;
    end
    
    // Compute the comparison result - split into two stages
    reg [4:0] sum_value;
    reg sum_ready;
    
    // First stage: compute sum
    always @(*) begin
        sum_value = counter + jitter;
    end
    
    // Second stage: compare with threshold
    always @(*) begin
        d0 = (sum_value >= 5'd16);
    end
    
    // Jitter calculation - split into two stages
    reg [1:0] jitter_part1;
    reg jitter_part2;
    reg jitter_ready;
    
    // First stage: compute jitter components
    always @(*) begin
        jitter_part1 = counter_buf1[1:0];
        jitter_part2 = ^counter_buf1;
    end
    
    // Second stage: combine jitter components
    always @(*) begin
        jitter_ready = (jitter_part2 & jitter_part1[0] & jitter_part1[1]) & jitter_en;
    end
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 5'd0;
            clk_out <= 1'b0;
            jitter <= 3'd0;
        end else begin
            jitter <= jitter_ready ? jitter_amount : 3'd0;
            if (d0_buf1) begin
                counter <= 5'd0;
                clk_out <= ~clk_out;
            end else
                counter <= counter + 5'd1;
        end
    end
endmodule