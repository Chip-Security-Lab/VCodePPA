module subtractor_with_cout (
    input wire [3:0] minuend,   // 被减数
    input wire [3:0] subtrahend, // 减数
    output wire [3:0] difference, // 差
    output wire cout            // 借位输出
);

assign {cout, difference} = minuend - subtrahend;  // 使用进位机制

endmodule