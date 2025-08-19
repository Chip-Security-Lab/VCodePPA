module Sub2(input [3:0] x, y, output [3:0] diff, output borrow);
    wire [3:0] borrow_out;
    
    // 最低位减法器
    assign diff[0] = x[0] ^ y[0];
    assign borrow_out[0] = ~x[0] & y[0];
    
    // 中间位减法器
    assign diff[1] = x[1] ^ y[1] ^ borrow_out[0];
    assign borrow_out[1] = (~x[1] & y[1]) | (~(x[1] ^ y[1]) & borrow_out[0]);
    
    assign diff[2] = x[2] ^ y[2] ^ borrow_out[1];
    assign borrow_out[2] = (~x[2] & y[2]) | (~(x[2] ^ y[2]) & borrow_out[1]);
    
    assign diff[3] = x[3] ^ y[3] ^ borrow_out[2];
    assign borrow_out[3] = (~x[3] & y[3]) | (~(x[3] ^ y[3]) & borrow_out[2]);
    
    // 最高位借位作为最终借位输出
    assign borrow = borrow_out[3];
endmodule