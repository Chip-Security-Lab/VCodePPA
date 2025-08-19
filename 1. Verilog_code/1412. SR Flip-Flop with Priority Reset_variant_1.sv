//SystemVerilog
module sr_ff_priority_reset (
    input wire clk,
    input wire s,
    input wire r,
    output reg q
);
    // Apply register retiming by moving registers forward through combinational logic
    // Directly process inputs in the main flip-flop logic
    always @(posedge clk) begin
        if (r)
            q <= 1'b0;  // Reset has priority
        else if (s)
            q <= 1'b1;  // Set
        else
            q <= q;     // No change
    end
endmodule