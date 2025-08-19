//SystemVerilog
module xor2_16 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    reg A_reg, B_reg;
    
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
    
    assign Y = A_reg ^ B_reg;
endmodule