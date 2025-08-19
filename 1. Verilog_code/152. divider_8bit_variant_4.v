// Top-level module
module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);
    // Internal signals
    wire [7:0] partial_quotient;
    wire [7:0] partial_remainder;
    wire [7:0] shifted_b;
    wire [3:0] count;
    wire done;
    
    // Control module
    divider_control ctrl (
        .clk(1'b0),  // Combinational logic
        .rst(1'b0),  // Combinational logic
        .start(1'b1), // Always start
        .count(count),
        .done(done)
    );
    
    // Datapath module with barrel shifter
    divider_datapath datapath (
        .a(a),
        .b(b),
        .count(count),
        .shifted_b(shifted_b),
        .partial_quotient(partial_quotient),
        .partial_remainder(partial_remainder)
    );
    
    // Output module
    divider_output out (
        .partial_quotient(partial_quotient),
        .partial_remainder(partial_remainder),
        .done(done),
        .quotient(quotient),
        .remainder(remainder)
    );
endmodule

// Control module
module divider_control (
    input clk,
    input rst,
    input start,
    output reg [3:0] count,
    output reg done
);
    // Simple counter for 8-bit division
    always @(*) begin
        if (rst) begin
            count = 4'b0;
            done = 1'b0;
        end else if (start) begin
            count = 4'b1000; // 8 iterations for 8-bit division
            done = 1'b1;
        end else begin
            count = 4'b0;
            done = 1'b0;
        end
    end
endmodule

// Datapath module with barrel shifter
module divider_datapath (
    input [7:0] a,
    input [7:0] b,
    input [3:0] count,
    output [7:0] shifted_b,
    output [7:0] partial_quotient,
    output [7:0] partial_remainder
);
    // Barrel shifter implementation
    wire [7:0] shift_1, shift_2, shift_4;
    
    // First level: shift by 1
    assign shift_1 = count[0] ? {b[6:0], 1'b0} : b;
    
    // Second level: shift by 2
    assign shift_2 = count[1] ? {shift_1[5:0], 2'b0} : shift_1;
    
    // Third level: shift by 4
    assign shift_4 = count[2] ? {shift_2[3:0], 4'b0} : shift_2;
    
    // Final output
    assign shifted_b = count[3] ? {shift_4[0], 7'b0} : shift_4;
    
    // Division logic
    assign partial_quotient = a / b;
    assign partial_remainder = a % b;
endmodule

// Output module
module divider_output (
    input [7:0] partial_quotient,
    input [7:0] partial_remainder,
    input done,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    always @(*) begin
        if (done) begin
            quotient = partial_quotient;
            remainder = partial_remainder;
        end else begin
            quotient = 8'b0;
            remainder = 8'b0;
        end
    end
endmodule