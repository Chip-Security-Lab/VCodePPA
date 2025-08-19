//SystemVerilog
// Top module
module nand2_14 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    // Internal connections
    wire nand_out;
    
    // Optimized NAND logic module instance
    nand_logic u_nand_logic (
        .clk(clk),
        .A(A),
        .B(B),
        .nand_out(nand_out)
    );
    
    // Output register module instance
    output_register u_output_register (
        .clk(clk),
        .nand_out(nand_out),
        .Y(Y)
    );
endmodule

// NAND logic module - optimized with backward register retiming
module nand_logic (
    input wire clk,
    input wire A, B,
    output wire nand_out
);
    // Registers moved backward through the combinational logic
    reg A_reg, B_reg;
    
    // Register input values
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
    
    // Combinational NAND without register
    assign nand_out = ~(A_reg & B_reg);
endmodule

// Output register module
module output_register (
    input wire clk,
    input wire nand_out,
    output reg Y
);
    // Register the output
    always @(posedge clk) begin
        Y <= nand_out;
    end
endmodule