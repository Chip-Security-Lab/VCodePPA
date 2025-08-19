module or_gate_3input_4bit_always (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output reg [3:0] y
);
    always @(*) begin
        y = a | b | c;
    end
endmodule