//SystemVerilog
module dual_clock_timer (
    input wire clk_fast, clk_slow, reset_n,
    input wire [15:0] target,
    output reg tick_out
);
    reg [15:0] counter_fast;
    reg match_detected;
    reg [1:0] sync_reg;
    
    // Buffered sync_reg signals to reduce fanout
    reg [1:0] sync_reg_buf1;
    reg [1:0] sync_reg_buf2;
    
    // Fast clock domain - Counter logic
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            counter_fast <= 16'h0000;
        end else begin
            counter_fast <= counter_fast + 1'b1;
        end
    end
    
    // Fast clock domain - Match detection logic
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            match_detected <= 1'b0;
        end else begin
            match_detected <= (counter_fast == target - 1'b1);
        end
    end
    
    // Slow clock domain - Clock domain crossing synchronization
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], match_detected};
        end
    end
    
    // Slow clock domain - Fanout reduction buffer stage 1
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg_buf1 <= 2'b00;
        end else begin
            sync_reg_buf1 <= sync_reg;
        end
    end
    
    // Slow clock domain - Fanout reduction buffer stage 2
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg_buf2 <= 2'b00;
        end else begin
            sync_reg_buf2 <= sync_reg;
        end
    end
    
    // Slow clock domain - Edge detection for output generation
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            tick_out <= 1'b0;
        end else begin
            tick_out <= sync_reg_buf1[0] & ~sync_reg_buf2[1];
        end
    end
endmodule