// 8-bit AND gate with delay
module and_gate_8_delay (
    input wire [7:0] a,  // 8-bit input A
    input wire [7:0] b,  // 8-bit input B
    output reg [7:0] y   // 8-bit output Y
);
    always @(a, b) begin
        #5 y = a & b;  // AND operation with 5-time unit delay
    end
endmodule
