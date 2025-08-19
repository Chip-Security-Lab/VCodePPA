module eq_based_xnor (a, b, y);
    input a, b;
    output reg y;

    always @(*) begin
        if (a == b) begin
            y = 1'b1;
        end else begin
            y = 1'b0;
        end
    end
endmodule