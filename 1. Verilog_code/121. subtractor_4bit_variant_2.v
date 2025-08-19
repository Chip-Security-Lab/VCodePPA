module subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);

    wire [3:0] borrow;
    wire [3:0] temp_diff;

    // 最低位减法
    assign temp_diff[0] = a[0] ^ b[0];
    assign borrow[0] = ~a[0] & b[0];

    // 中间位减法
    assign temp_diff[1] = a[1] ^ b[1] ^ borrow[0];
    assign borrow[1] = (~a[1] & b[1]) | (b[1] & borrow[0]) | (~a[1] & borrow[0]);

    assign temp_diff[2] = a[2] ^ b[2] ^ borrow[1];
    assign borrow[2] = (~a[2] & b[2]) | (b[2] & borrow[1]) | (~a[2] & borrow[1]);

    // 最高位减法
    assign temp_diff[3] = a[3] ^ b[3] ^ borrow[2];
    assign borrow[3] = (~a[3] & b[3]) | (b[3] & borrow[2]) | (~a[3] & borrow[2]);

    assign diff = temp_diff;

endmodule