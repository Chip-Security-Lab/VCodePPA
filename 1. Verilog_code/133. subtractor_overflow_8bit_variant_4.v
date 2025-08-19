module subtractor_overflow_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output overflow
);

    // 借位信号
    wire [8:0] borrow;
    wire [7:0] b_inv;
    
    // 取反b
    assign b_inv = ~b;
    
    // 初始借位为1
    assign borrow[0] = 1'b1;
    
    // 展开的借位减法器实现
    // 第0位
    assign diff[0] = a[0] ^ b_inv[0] ^ borrow[0];
    assign borrow[1] = (~a[0] & b_inv[0]) | (~a[0] & borrow[0]) | (b_inv[0] & borrow[0]);
    
    // 第1位
    assign diff[1] = a[1] ^ b_inv[1] ^ borrow[1];
    assign borrow[2] = (~a[1] & b_inv[1]) | (~a[1] & borrow[1]) | (b_inv[1] & borrow[1]);
    
    // 第2位
    assign diff[2] = a[2] ^ b_inv[2] ^ borrow[2];
    assign borrow[3] = (~a[2] & b_inv[2]) | (~a[2] & borrow[2]) | (b_inv[2] & borrow[2]);
    
    // 第3位
    assign diff[3] = a[3] ^ b_inv[3] ^ borrow[3];
    assign borrow[4] = (~a[3] & b_inv[3]) | (~a[3] & borrow[3]) | (b_inv[3] & borrow[3]);
    
    // 第4位
    assign diff[4] = a[4] ^ b_inv[4] ^ borrow[4];
    assign borrow[5] = (~a[4] & b_inv[4]) | (~a[4] & borrow[4]) | (b_inv[4] & borrow[4]);
    
    // 第5位
    assign diff[5] = a[5] ^ b_inv[5] ^ borrow[5];
    assign borrow[6] = (~a[5] & b_inv[5]) | (~a[5] & borrow[5]) | (b_inv[5] & borrow[5]);
    
    // 第6位
    assign diff[6] = a[6] ^ b_inv[6] ^ borrow[6];
    assign borrow[7] = (~a[6] & b_inv[6]) | (~a[6] & borrow[6]) | (b_inv[6] & borrow[6]);
    
    // 第7位
    assign diff[7] = a[7] ^ b_inv[7] ^ borrow[7];
    assign borrow[8] = (~a[7] & b_inv[7]) | (~a[7] & borrow[7]) | (b_inv[7] & borrow[7]);
    
    // 溢出检测
    assign overflow = (a[7] & ~b[7] & ~diff[7]) | (~a[7] & b[7] & diff[7]);

endmodule