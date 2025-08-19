//SystemVerilog
// Top module
module nand2_16 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    // Internal signals for module connections
    wire A_registered;
    wire B_registered;
    
    // Instantiate input register module
    input_register input_reg_inst (
        .clk(clk),
        .A_in(A),
        .B_in(B),
        .A_out(A_registered),
        .B_out(B_registered)
    );
    
    // Instantiate logic operation module
    logic_operation logic_op_inst (
        .A(A_registered),
        .B(B_registered),
        .Y(Y)
    );
endmodule

// Input register module
module input_register (
    input wire clk,
    input wire A_in, B_in,
    output reg A_out, B_out
);
    // Register the input signals
    always @(posedge clk) begin
        A_out <= A_in;
        B_out <= B_in;
    end
endmodule

// Logic operation module
module logic_operation (
    input wire A, B,
    output wire Y
);
    // Perform NAND operation
    assign Y = ~(A & B);
endmodule