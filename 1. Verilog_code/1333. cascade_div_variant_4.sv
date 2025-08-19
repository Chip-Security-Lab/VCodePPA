//SystemVerilog
module cascade_div #(parameter DEPTH=3) (
    input clk, en,
    output [DEPTH:0] div_out
);
    // Buffered clock tree
    wire [DEPTH:0] clk_div;
    reg [DEPTH:0] clk_div_buf [1:0];  // Two-level buffering for high fanout clock
    
    assign clk_div[0] = clk;
    assign div_out = clk_div;
    
    // Distribute clock load with buffers
    always @(posedge clk) begin
        clk_div_buf[0] <= clk_div;
        clk_div_buf[1] <= clk_div_buf[0];
    end

    genvar i;
    generate
        for(i=0;i<DEPTH;i++) begin : stage
            reg [1:0] cnt;
            wire [1:0] next_cnt;
            reg [1:0] next_cnt_buf [1:0];  // Buffered next_cnt to reduce fanout
            
            // Brent-Kung adder with reduced fanout
            wire p0, p1, g0, g1;
            reg [1:0] p_buf [1:0];  // Buffered propagate signals
            wire pg, carry;
            
            // Generate propagate and generate signals
            assign p0 = cnt[0];
            assign g0 = 1'b0;  // Since adding with 1, g0 is always 0
            assign p1 = cnt[1];
            assign g1 = cnt[1] & cnt[0];  // g1 = cnt[1] & p0
            
            // Buffer high fanout propagate signals
            always @(posedge clk_div[i]) begin
                p_buf[0][0] <= p0;
                p_buf[0][1] <= p1;
                p_buf[1][0] <= p_buf[0][0];
                p_buf[1][1] <= p_buf[0][1];
            end
            
            // Group propagate and generate
            assign pg = p_buf[0][1] & p_buf[0][0];
            assign carry = g1 | (p_buf[1][1] & g0);
            
            // Calculate sum with buffered signals to balance loads
            assign next_cnt[0] = p_buf[1][0] ^ 1'b1;  // XOR with input 1
            assign next_cnt[1] = p_buf[1][1] ^ carry;
            
            // Buffer next_cnt to reduce fanout
            always @(posedge clk_div[i]) begin
                next_cnt_buf[0] <= next_cnt;
                next_cnt_buf[1] <= next_cnt_buf[0];
            end
            
            // Register update with buffered signals
            always @(posedge clk_div_buf[i%2][i]) begin
                if(!en) begin
                    cnt <= 2'b00;
                end else begin
                    cnt <= next_cnt_buf[1];
                end
            end
            
            assign clk_div[i+1] = cnt[1];
        end
    endgenerate
endmodule