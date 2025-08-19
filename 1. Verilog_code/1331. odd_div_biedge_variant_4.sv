//SystemVerilog
module odd_div_biedge #(parameter N=5) (
    input clk, rst_n,
    output reg clk_out
);
    // Counters for positive and negative edges
    reg [2:0] pos_cnt;
    reg [2:0] neg_cnt;
    
    // Intermediate signals for improved timing
    reg pos_out_next;
    reg neg_out_next;
    reg pos_out;
    reg neg_out;
    
    // Conditional sum subtraction implementation for counter increment
    wire [2:0] pos_cnt_incr;
    wire [2:0] neg_cnt_incr;
    wire pos_cnt_carry0, pos_cnt_carry1;
    wire neg_cnt_carry0, neg_cnt_carry1;
    
    // Positive counter conditional sum subtraction
    assign pos_cnt_carry0 = pos_cnt[0];
    assign pos_cnt_carry1 = pos_cnt[1] & pos_cnt_carry0;
    assign pos_cnt_incr[0] = ~pos_cnt[0];
    assign pos_cnt_incr[1] = pos_cnt[1] ^ pos_cnt_carry0;
    assign pos_cnt_incr[2] = pos_cnt[2] ^ pos_cnt_carry1;
    
    // Negative counter conditional sum subtraction
    assign neg_cnt_carry0 = neg_cnt[0];
    assign neg_cnt_carry1 = neg_cnt[1] & neg_cnt_carry0;
    assign neg_cnt_incr[0] = ~neg_cnt[0];
    assign neg_cnt_incr[1] = neg_cnt[1] ^ neg_cnt_carry0;
    assign neg_cnt_incr[2] = neg_cnt[2] ^ neg_cnt_carry1;
    
    // Next counter values with reset logic
    wire [2:0] pos_cnt_next = (pos_cnt == N-1) ? 3'b0 : pos_cnt_incr;
    wire [2:0] neg_cnt_next = (neg_cnt == N-1) ? 3'b0 : neg_cnt_incr;
    
    // Positive edge logic with retimed registers
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pos_cnt <= 0;
            pos_out <= 0;
            pos_out_next <= 0;
        end else begin
            pos_cnt <= pos_cnt_next;
            pos_out <= pos_out_next;
            
            // Pre-compute next output state
            if(pos_cnt_next == N-1)
                pos_out_next <= ~pos_out_next;
        end
    end

    // Negative edge logic with retimed registers
    always @(negedge clk or negedge rst_n) begin
        if(!rst_n) begin
            neg_cnt <= 0;
            neg_out <= 0;
            neg_out_next <= 0;
        end else begin
            neg_cnt <= neg_cnt_next;
            neg_out <= neg_out_next;
            
            // Pre-compute next output state
            if(neg_cnt_next == N-1)
                neg_out_next <= ~neg_out_next;
        end
    end

    // Output generation with registered output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            clk_out <= 1'b0;
        else
            clk_out <= pos_out ^ neg_out;
    end
endmodule