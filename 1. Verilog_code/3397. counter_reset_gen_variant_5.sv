//SystemVerilog
module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    reg [3:0] counter;
    wire [3:0] next_count;
    
    // Carry look-ahead adder signals
    wire [3:0] p, g;  // propagate and generate signals
    wire [4:0] c;     // carry signals (includes input carry)
    
    // Generate propagate and generate signals
    assign p = counter;  // Propagate when counter bit is 1
    assign g = 4'b0000;  // Generate is 0 (we're adding 1)
    
    // Calculate carries using carry look-ahead logic
    assign c[0] = 1'b1;  // Input carry (adding 1)
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum calculation using XOR
    assign next_count[0] = p[0] ^ c[0];
    assign next_count[1] = p[1] ^ c[1];
    assign next_count[2] = p[2] ^ c[2];
    assign next_count[3] = p[3] ^ c[3];
    
    always @(posedge clk) begin
        if (!enable)
            counter <= 4'b0;
        else if (counter != THRESHOLD)
            counter <= next_count;
            
        // Output logic remains separated from counter logic
        reset_out <= (counter == (THRESHOLD - 1'b1) && enable) ? 1'b1 : 1'b0;
    end
endmodule