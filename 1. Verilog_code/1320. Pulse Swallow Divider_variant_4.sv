//SystemVerilog
module pulse_swallow_div (
    input clk_in, reset, swallow_en,
    input [3:0] swallow_val,
    output reg clk_out
);
    reg [3:0] counter;
    reg swallow;
    
    // Manchester carry chain signals
    wire [3:0] p, g;
    wire [4:0] c;
    
    // Generate and propagate signals
    assign p = counter;             // Propagate when bit is 1
    assign g = 4'b0000;             // No generate for simple increment
    
    // Manchester carry chain implementation
    assign c[0] = 1'b1;             // Carry-in for increment
    assign c[1] = p[0] & c[0];      // Carry calculation for each bit
    assign c[2] = p[1] & c[1];
    assign c[3] = p[2] & c[2];
    assign c[4] = p[3] & c[3];
    
    // Sum calculation using Manchester carry chain
    wire [3:0] counter_next;
    assign counter_next[0] = p[0] ^ c[0];
    assign counter_next[1] = p[1] ^ c[1];
    assign counter_next[2] = p[2] ^ c[2];
    assign counter_next[3] = p[3] ^ c[3];
    
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 4'd0;
            clk_out <= 1'b0;
            swallow <= 1'b0;
        end else if (swallow_en && counter == swallow_val) begin
            swallow <= 1'b1;
        end else if (counter == 4'd7) begin
            counter <= 4'd0;
            clk_out <= ~clk_out;
            swallow <= 1'b0;
        end else if (!swallow)
            counter <= counter_next; // Use Manchester carry chain adder
    end
endmodule