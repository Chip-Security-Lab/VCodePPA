module dual_clock_timer (
    input wire clk_fast, clk_slow, reset_n,
    input wire [15:0] target,
    output reg tick_out
);
    reg [15:0] counter_fast;
    reg match_detected;
    reg [1:0] sync_reg;
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            counter_fast <= 16'h0000;
            match_detected <= 1'b0;
        end else begin
            counter_fast <= counter_fast + 1'b1;
            match_detected <= (counter_fast == target - 1'b1);
        end
    end
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg <= 2'b00; tick_out <= 1'b0;
        end else begin
            sync_reg <= {sync_reg[0], match_detected};
            tick_out <= sync_reg[0] & ~sync_reg[1]; // Rising edge detect
        end
    end
endmodule