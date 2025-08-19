//SystemVerilog
module SyncNor(
    input  clk,
    input  rst,
    input  a,
    input  b,
    output reg y
);
    reg a_reg, b_reg;

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    always @(posedge clk) begin
        if (rst)
            y <= 1'b0;
        else
            y <= (~a_reg) & (~b_reg);
    end
endmodule