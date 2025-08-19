module SatDiv(
    input [7:0] a, b,
    output reg [7:0] q
);
    always @(*) begin
        if(b == 0) q = 8'hFF;
        else q = a / b;
    end
endmodule