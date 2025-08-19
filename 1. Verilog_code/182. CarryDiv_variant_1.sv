//SystemVerilog
module CarryDiv(
    input [3:0] D, d,
    output [3:0] q
);
    wire [3:0] p = D - d;
    reg [3:0] temp_q;

    always @* begin
        if (p[3]) begin
            temp_q = 4'b0001;  // {3'b0, 1'b1}
        end else begin
            temp_q = 4'b0000;  // {3'b0, 1'b0} + 1
        end
    end

    assign q = temp_q;
endmodule