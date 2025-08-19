//SystemVerilog
module TimerAsyncCmp #(parameter CMP_VAL=8'hFF) (
    input clk, rst_n,
    output reg timer_trigger
);
    reg [7:0] cnt;
    wire [7:0] next_cnt;
    
    // Manchester carry chain adder implementation
    wire [7:0] p; // Propagate signals
    wire [8:0] c; // Carry signals
    
    // Generate propagate signals
    assign p = cnt ^ 8'h01;
    
    // Initial carry-in
    assign c[0] = 1'b0;
    
    // Manchester carry chain implementation
    assign c[1] = (cnt[0] & 1'b1) | (p[0] & c[0]);
    assign c[2] = (cnt[1] & 1'b0) | (p[1] & c[1]);
    assign c[3] = (cnt[2] & 1'b0) | (p[2] & c[2]);
    assign c[4] = (cnt[3] & 1'b0) | (p[3] & c[3]);
    assign c[5] = (cnt[4] & 1'b0) | (p[4] & c[4]);
    assign c[6] = (cnt[5] & 1'b0) | (p[5] & c[5]);
    assign c[7] = (cnt[6] & 1'b0) | (p[6] & c[6]);
    assign c[8] = (cnt[7] & 1'b0) | (p[7] & c[7]);
    
    // Sum calculation
    assign next_cnt[0] = cnt[0] ^ 1'b1 ^ c[0];
    assign next_cnt[1] = cnt[1] ^ 1'b0 ^ c[1];
    assign next_cnt[2] = cnt[2] ^ 1'b0 ^ c[2];
    assign next_cnt[3] = cnt[3] ^ 1'b0 ^ c[3];
    assign next_cnt[4] = cnt[4] ^ 1'b0 ^ c[4];
    assign next_cnt[5] = cnt[5] ^ 1'b0 ^ c[5];
    assign next_cnt[6] = cnt[6] ^ 1'b0 ^ c[6];
    assign next_cnt[7] = cnt[7] ^ 1'b0 ^ c[7];
    
    // Pre-computed comparison with CMP_VAL (moved before register)
    wire next_timer_trigger = (next_cnt == CMP_VAL);
    
    // Counter update logic with integrated comparison
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cnt <= 8'h0;
            timer_trigger <= 1'b0;
        end
        else begin
            cnt <= next_cnt;
            timer_trigger <= next_timer_trigger;
        end
    
endmodule