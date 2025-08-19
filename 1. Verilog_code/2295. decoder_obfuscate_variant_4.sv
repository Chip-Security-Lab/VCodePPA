//SystemVerilog
module decoder_obfuscate #(parameter KEY=8'hA5) (
    input [7:0] cipher_addr,
    output reg [15:0] decoded
);
    // 使用reg类型以便在always块中赋值
    wire [7:0] real_addr;
    
    // 异或解密
    assign real_addr = cipher_addr ^ KEY;
    
    // 使用always块代替连续赋值以优化比较逻辑
    always @(*) begin
        if (real_addr[7:4] == 4'b0000) begin   // 检查高4位是否为0
            if (real_addr[3:0] < 4'd16) begin  // 检查低4位的范围
                decoded = 16'h1 << real_addr[3:0]; // 移位操作
            end
            else begin
                decoded = 16'h0;
            end
        end
        else begin
            decoded = 16'h0; // 如果高4位不全为0，则输出0
        end
    end
endmodule