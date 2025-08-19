// 4-bit AND gate with enable signal
module and_gate_4_enable (
    input wire [3:0] a,      // 4-bit input A
    input wire [3:0] b,      // 4-bit input B
    input wire enable,       // Enable signal
    output wire [3:0] y      // 4-bit output Y
);
    assign y = (enable) ? (a & b) : 4'b0000;  // AND operation with enable
endmodule
