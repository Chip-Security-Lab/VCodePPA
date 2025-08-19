module not_gate_async_reset (
    input wire A,
    input wire clk,  // Added missing clock input
    input wire reset,
    output reg Y
);
    // Conventional edge-based sensitivity list
    always @(posedge clk or posedge reset) begin
        if (reset)
            Y <= 0;
        else
            Y <= ~A;
    end
endmodule