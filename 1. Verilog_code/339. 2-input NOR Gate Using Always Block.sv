module nor2_assign (
    input wire A, B,
    output reg Y  // Changed from wire to reg since it's assigned in an always block
);
    always @(*) begin
        Y = ~(A | B);  // 使用 always 块进行赋值
    end
endmodule