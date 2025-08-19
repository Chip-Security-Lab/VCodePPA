//SystemVerilog
module cascade_div #(parameter DEPTH=3) (
    input wire clk, 
    input wire en,
    output wire [DEPTH:0] div_out
);
    reg [DEPTH:0] clk_div_reg;
    wire [DEPTH:0] clk_div;
    reg [DEPTH:0] clk_div_buf1, clk_div_buf2;  // Multiple buffer stages for high fan-out clock signals
    
    // First stage directly connects to input clock
    assign clk_div[0] = clk;
    
    // Clock distribution buffers
    always @(posedge clk) begin
        clk_div_buf1[0] <= clk_div[0];
        clk_div_buf2[0] <= clk_div_buf1[0];
    end
    
    // Output assignment with registered outputs to reduce load
    reg [DEPTH:0] div_out_reg;
    always @(posedge clk) begin
        div_out_reg <= clk_div;
    end
    assign div_out = div_out_reg;
    
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : stage
            // Pre-calculate next value using Han-Carlson adder
            wire [1:0] next_cnt;
            reg [1:0] cnt;
            reg [1:0] cnt_buf1, cnt_buf2; // Buffered cnt signals
            
            // Han-Carlson adder implementation (2-bit)
            // Propagate and generate signals with buffers
            wire [1:0] p, g;
            reg [1:0] p_buf1, p_buf2;     // Buffered p signals
            reg [1:0] g_buf1, g_buf2;     // Buffered g signals
            wire [1:0] p_prefix, g_prefix;
            reg [1:0] p_prefix_buf, g_prefix_buf; // Buffered prefix signals
            
            // Step 1: Generate p and g signals
            assign p[0] = cnt[0];
            assign g[0] = 1'b0; // For addition with 1, g[0] is always 0
            assign p[1] = cnt[1];
            assign g[1] = cnt[1] & cnt[0];
            
            // Buffer p and g signals to reduce fanout
            always @(posedge clk_div_buf1[i]) begin
                p_buf1 <= p;
                g_buf1 <= g;
            end
            
            always @(posedge clk_div_buf1[i]) begin
                p_buf2 <= p_buf1;
                g_buf2 <= g_buf1;
            end
            
            // Step 2: Prefix computation (for 2-bit, this is simple)
            assign p_prefix[0] = p_buf2[0];
            assign g_prefix[0] = g_buf2[0];
            assign p_prefix[1] = p_buf2[1] & p_buf2[0];
            assign g_prefix[1] = g_buf2[1] | (p_buf2[1] & g_buf2[0]);
            
            // Buffer prefix signals
            always @(posedge clk_div_buf2[i]) begin
                p_prefix_buf <= p_prefix;
                g_prefix_buf <= g_prefix;
            end
            
            // Step 3: Generate sum with buffered signals
            wire carry_in = en; // Carry in is 1 when enabled (adding 1)
            reg carry_in_buf1, carry_in_buf2; // Buffered enable signal
            
            always @(posedge clk_div_buf1[i]) begin
                carry_in_buf1 <= carry_in;
                carry_in_buf2 <= carry_in_buf1;
            end
            
            wire [1:0] sum;
            reg [1:0] sum_buf1, sum_buf2; // Buffered sum signals
            
            assign sum[0] = p_prefix_buf[0] ^ carry_in_buf2;
            assign sum[1] = p_prefix_buf[1] ^ (g_prefix_buf[0] | (p_prefix_buf[0] & carry_in_buf2));
            
            // Buffer sum signals
            always @(posedge clk_div_buf2[i]) begin
                sum_buf1 <= sum;
                sum_buf2 <= sum_buf1;
            end
            
            // Final output assignment with reduced fanout
            assign next_cnt = (!carry_in_buf2) ? 2'b00 : sum_buf2;
            
            // Register update on clock edge with buffered clock
            always @(posedge clk_div_buf2[i]) begin
                cnt <= next_cnt;
                cnt_buf1 <= cnt;
                cnt_buf2 <= cnt_buf1;
            end
            
            // Buffer the output to reduce load on critical path
            // and improve fan-out capability with multi-stage buffering
            always @(posedge clk_div_buf2[i]) begin
                clk_div_reg[i+1] <= cnt_buf2[1];
            end
            
            // Assign to output wire through register to balance paths
            assign clk_div[i+1] = clk_div_reg[i+1];
            
            // Clock distribution buffers for next stage
            always @(posedge clk) begin
                clk_div_buf1[i+1] <= clk_div[i+1];
                clk_div_buf2[i+1] <= clk_div_buf1[i+1];
            end
        end
    endgenerate
endmodule