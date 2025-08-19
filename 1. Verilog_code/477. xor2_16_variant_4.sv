//SystemVerilog
module xor2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    // Register inputs first
    reg A_reg, B_reg;
    
    // Input registers
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
    
    // Combinational logic after registers
    always @(posedge clk) begin
        Y <= A_reg ^ B_reg;
    end
endmodule