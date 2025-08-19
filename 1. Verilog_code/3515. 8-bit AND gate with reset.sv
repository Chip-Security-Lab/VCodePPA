// 8-bit AND gate with reset
module and_gate_8bit_reset (
    input wire [7:0] a,    // 8-bit input A
    input wire [7:0] b,    // 8-bit input B
    input wire rst,        // Reset signal
    output wire [7:0] y    // 8-bit output Y
);
    assign y = (rst) ? 8'b00000000 : (a & b);  // AND operation with reset
endmodule
