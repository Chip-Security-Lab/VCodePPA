//SystemVerilog
module rom_thermometer #(parameter N=8)(
    input [2:0] val,
    output reg [N-1:0] code
);
    wire [N-1:0] shifted_value;
    reg [N:0] borrow;
    integer i;
    
    // 生成左移的值 (1 << val)
    assign shifted_value = 1 << val;
    
    // 使用借位减法器算法实现减法
    always @(*) begin
        borrow[0] = 0;
        for (i = 0; i < N; i = i + 1) begin
            // 对于 (1 << val) - 1:
            // 第一个操作数为shifted_value的对应位
            // 第二个操作数恒为1
            // 借位减法器实现: result[i] = a[i] ^ b[i] ^ borrow_in
            // 下一位借位: borrow_out = (~a[i] & b[i]) | (~a[i] & borrow_in) | (b[i] & borrow_in)
            code[i] = shifted_value[i] ^ 1 ^ borrow[i];
            borrow[i+1] = (~shifted_value[i] & 1) | (~shifted_value[i] & borrow[i]) | (1 & borrow[i]);
        end
    end
endmodule