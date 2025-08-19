//SystemVerilog
module simple_4bit_divider (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);

    // Optimized division using combinational logic
    wire [3:0] q0, q1, q2, q3;
    wire [3:0] r0, r1, r2, r3;
    
    // Stage 0: Compare with 8
    assign q0 = (a >= {b, 1'b0}) ? 4'b1000 : 4'b0000;
    assign r0 = (a >= {b, 1'b0}) ? a - {b, 1'b0} : a;
    
    // Stage 1: Compare with 4
    assign q1 = (r0 >= b) ? 4'b0100 : 4'b0000;
    assign r1 = (r0 >= b) ? r0 - b : r0;
    
    // Stage 2: Compare with 2
    assign q2 = (r1 >= {1'b0, b[3:1]}) ? 4'b0010 : 4'b0000;
    assign r2 = (r1 >= {1'b0, b[3:1]}) ? r1 - {1'b0, b[3:1]} : r1;
    
    // Stage 3: Compare with 1
    assign q3 = (r2 >= {2'b00, b[3:2]}) ? 4'b0001 : 4'b0000;
    assign r3 = (r2 >= {2'b00, b[3:2]}) ? r2 - {2'b00, b[3:2]} : r2;
    
    // Final results
    assign quotient = (b == 0) ? 4'hF : (q0 | q1 | q2 | q3);
    assign remainder = (b == 0) ? 4'hF : r3;

endmodule