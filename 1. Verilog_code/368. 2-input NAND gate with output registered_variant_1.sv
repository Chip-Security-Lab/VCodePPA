//SystemVerilog
module nand2_10 (
    input wire [7:0] A,
    input wire [7:0] B,
    output reg [15:0] Y
);
    integer i;
    reg [15:0] partial_sum;
    always @* begin
        partial_sum = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (B[i])
                partial_sum = partial_sum + (A << i);
        end
        Y = ~partial_sum;
    end
endmodule