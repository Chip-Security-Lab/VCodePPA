// AND gate with clock signal
module and_gate_clock (
    input wire clk,    // Clock signal
    input wire a,      // Input A
    input wire b,      // Input B
    output reg y       // Output Y
);
    always @(posedge clk) begin
        y <= a & b;  // AND operation on rising edge of clock
    end
endmodule
