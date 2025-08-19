//SystemVerilog
module parity_decoder(
    input [2:0] addr,
    input parity_bit,
    output reg [7:0] select,
    output reg parity_error
);
    // 计算期望的奇偶校验位
    wire expected_parity;
    assign expected_parity = addr[0] ^ addr[1] ^ addr[2]; // 显式展开XOR操作，提高清晰度

    always @(*) begin
        // 比较计算出的奇偶校验位与输入的奇偶校验位
        parity_error = expected_parity ^ parity_bit; // 使用XOR代替不等于操作
        
        // 使用条件运算符简化逻辑，减少分支
        select = parity_error ? 8'b0 : (8'b00000001 << addr);
    end
endmodule