module adaptive_quant(
    input [31:0] f,
    input [7:0] bits,
    output reg [31:0] q
);
    reg [31:0] scale;
    reg [63:0] temp; // 扩展位宽防止溢出
    
    always @(*) begin
        scale = 1 << bits;
        temp = f * scale;
        
        // 溢出检测和处理
        if (f[31] == 0 && temp[63:31] != 0) // 正数溢出
            q = 32'h7FFFFFFF; // (2^31)-1
        else if (f[31] == 1 && temp[63:31] != {33{1'b1}}) // 负数溢出
            q = 32'h80000000; // -(2^31)
        else
            q = temp[31:0];
    end
endmodule