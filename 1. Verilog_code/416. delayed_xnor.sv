module delayed_xnor (a, b, y);
    input wire a, b;
    output reg y;

    always @(*) begin
        #1 y = ~(a ^ b); // 假设添加 1 个时钟周期的延迟
    end
endmodule