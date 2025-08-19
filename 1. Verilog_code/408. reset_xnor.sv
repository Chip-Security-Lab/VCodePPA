module reset_xnor (a, b, reset, y);
    input a, b, reset;
    output reg y;

    always @(*) begin
        if (reset) begin
            y = 1'b0;
        end else begin
            y = ~(a ^ b);
        end
    end
endmodule