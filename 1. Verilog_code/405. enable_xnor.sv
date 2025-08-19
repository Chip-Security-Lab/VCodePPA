module enable_xnor (enable, a, b, y);
    input enable, a, b;
    output reg y;

    always @(*) begin
        if (enable) begin
            y = ~(a ^ b);
        end else begin
            y = 1'b0;
        end
    end
endmodule