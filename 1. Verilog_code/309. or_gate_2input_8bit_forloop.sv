module or_gate_2input_8bit_forloop (
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] y
);
    integer i;
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            y[i] = a[i] | b[i];
        end
    end
endmodule