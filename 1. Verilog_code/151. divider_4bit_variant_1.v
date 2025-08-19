module divider_4bit (
    input [3:0] a,  // 被除数
    input [3:0] b,  // 除数
    output [3:0] quotient,  // 商
    output [3:0] remainder  // 余数
);
    // 内部信号定义
    reg [3:0] q;         // 商寄存器
    reg [7:0] dividend;  // 被除数寄存器 (扩展为8位以支持移位操作)
    reg [3:0] divisor;   // 除数寄存器
    reg [3:0] r;         // 余数寄存器
    integer i;           // 循环计数器
    
    // Han-Carlson加法器相关信号
    wire [3:0] sum;      // 加法器结果
    wire [3:0] carry;    // 进位信号
    wire [3:0] p;        // 传播信号
    wire [3:0] g;        // 生成信号
    
    // Han-Carlson加法器实现
    assign p = r ^ divisor;
    assign g = r & divisor;
    
    // 第一级进位计算
    wire [1:0] c1;
    assign c1[0] = g[0] | (p[0] & 1'b0);
    assign c1[1] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    
    // 第二级进位计算
    wire [3:0] c2;
    assign c2[0] = c1[0];
    assign c2[1] = g[1] | (p[1] & c1[0]);
    assign c2[2] = c1[1];
    assign c2[3] = g[3] | (p[3] & c1[1]);
    
    // 最终和计算
    assign sum = p ^ {c2[2:0], 1'b0};
    assign carry = c2;
    
    // 组合逻辑实现移位减法除法算法
    always @(*) begin
        // 初始化
        dividend = {4'b0, a};  // 被除数左移4位
        divisor = b;
        q = 4'b0;
        r = 4'b0;
        
        // 移位减法除法算法
        for (i = 0; i < 4; i = i + 1) begin
            // 左移商和余数
            q = {q[2:0], 1'b0};
            r = {r[2:0], dividend[7]};
            dividend = {dividend[6:0], 1'b0};
            
            // 使用Han-Carlson加法器进行减法比较
            if (r >= divisor) begin
                r = sum;
                q[0] = 1'b1;
            end
        end
    end
    
    // 输出赋值
    assign quotient = q;
    assign remainder = r;
endmodule