//SystemVerilog
module SignedDiv(
    input signed [7:0] num, den,
    output reg signed [7:0] q
);

    // 除法运算子模块
    DivCore div_core(
        .num(num),
        .den(den),
        .q(q)
    );

endmodule

module DivCore(
    input signed [7:0] num, den,
    output reg signed [7:0] q
);

    always @(*) begin
        if (den != 0) begin
            q = num / den;
        end else begin
            q = 8'h80;
        end
    end

endmodule