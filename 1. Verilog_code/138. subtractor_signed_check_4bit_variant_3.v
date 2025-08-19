module subtractor_signed_check_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff,
    output negative
);

    // 实例化借位减法器子模块
    borrow_subtractor_4bit u_subtractor (
        .a(a),
        .b(b),
        .diff(diff)
    );

    // 实例化符号检测子模块
    sign_detector u_sign_detector (
        .diff(diff),
        .negative(negative)
    );

endmodule

// 借位减法器子模块
module borrow_subtractor_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff
);
    wire [3:0] borrow;
    wire [3:0] temp_diff;
    
    // 初始化借位信号
    assign borrow[0] = 1'b0;
    
    // 第0位减法
    assign temp_diff[0] = a[0] ^ b[0] ^ borrow[0];
    assign borrow[1] = (~a[0] & b[0]) | ((~a[0] | b[0]) & borrow[0]);
    
    // 第1位减法
    assign temp_diff[1] = a[1] ^ b[1] ^ borrow[1];
    assign borrow[2] = (~a[1] & b[1]) | ((~a[1] | b[1]) & borrow[1]);
    
    // 第2位减法
    assign temp_diff[2] = a[2] ^ b[2] ^ borrow[2];
    assign borrow[3] = (~a[2] & b[2]) | ((~a[2] | b[2]) & borrow[2]);
    
    // 第3位减法
    assign temp_diff[3] = a[3] ^ b[3] ^ borrow[3];
    
    // 输出结果
    assign diff = temp_diff;
endmodule

// 符号检测子模块
module sign_detector (
    input signed [3:0] diff,
    output negative
);
    assign negative = (diff[3] == 1);
endmodule