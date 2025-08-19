//SystemVerilog
// AND gate with clock signal and backward register retiming
module and_gate_clock (
    input wire clk,    // Clock signal
    input wire a,      // Input A
    input wire b,      // Input B
    output wire y      // Output Y
);
    // Registered inputs
    reg a_reg, b_reg;
    
    // Register the inputs instead of the output
    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
    end
    
    // Combinational output using registered inputs
    assign y = a_reg & b_reg;
    
endmodule