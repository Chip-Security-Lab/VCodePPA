module subtractor_multi_input (
    input wire [3:0] a,   // 被减数 1
    input wire [3:0] b,   // 被减数 2
    input wire [3:0] c,   // 被减数 3
    input wire [3:0] d,   // 减数
    output wire [3:0] res // 差
);

// 优化后的信号定义
wire [3:0] sum_ab;    // a + b 的和
wire [3:0] sum_abc;   // a + b + c 的和
wire [3:0] carry_ab;  // a + b 的进位
wire [3:0] carry_abc; // a + b + c 的进位
wire [3:0] borrow;    // 减法借位

// 第一级加法: a + b
assign carry_ab[0] = a[0] & b[0];
assign sum_ab[0] = a[0] ^ b[0];
assign carry_ab[1] = (a[1] & b[1]) | ((a[1] ^ b[1]) & carry_ab[0]);
assign sum_ab[1] = a[1] ^ b[1] ^ carry_ab[0];
assign carry_ab[2] = (a[2] & b[2]) | ((a[2] ^ b[2]) & carry_ab[1]);
assign sum_ab[2] = a[2] ^ b[2] ^ carry_ab[1];
assign carry_ab[3] = (a[3] & b[3]) | ((a[3] ^ b[3]) & carry_ab[2]);
assign sum_ab[3] = a[3] ^ b[3] ^ carry_ab[2];

// 第二级加法: sum_ab + c
assign carry_abc[0] = sum_ab[0] & c[0];
assign sum_abc[0] = sum_ab[0] ^ c[0];
assign carry_abc[1] = (sum_ab[1] & c[1]) | ((sum_ab[1] ^ c[1]) & carry_abc[0]);
assign sum_abc[1] = sum_ab[1] ^ c[1] ^ carry_abc[0];
assign carry_abc[2] = (sum_ab[2] & c[2]) | ((sum_ab[2] ^ c[2]) & carry_abc[1]);
assign sum_abc[2] = sum_ab[2] ^ c[2] ^ carry_abc[1];
assign carry_abc[3] = (sum_ab[3] & c[3]) | ((sum_ab[3] ^ c[3]) & carry_abc[2]);
assign sum_abc[3] = sum_ab[3] ^ c[3] ^ carry_abc[2];

// 第三级减法: sum_abc - d
assign borrow[0] = ~sum_abc[0] & d[0];
assign res[0] = sum_abc[0] ^ d[0];
assign borrow[1] = (~sum_abc[1] & d[1]) | ((sum_abc[1] ^ d[1]) & borrow[0]);
assign res[1] = sum_abc[1] ^ d[1] ^ borrow[0];
assign borrow[2] = (~sum_abc[2] & d[2]) | ((sum_abc[2] ^ d[2]) & borrow[1]);
assign res[2] = sum_abc[2] ^ d[2] ^ borrow[1];
assign borrow[3] = (~sum_abc[3] & d[3]) | ((sum_abc[3] ^ d[3]) & borrow[2]);
assign res[3] = sum_abc[3] ^ d[3] ^ borrow[2];

endmodule