// 查找表子模块
module lut_4bit(
    input [3:0] addr,
    output reg out
);
    reg [3:0] lut [0:15];
    
    initial begin
        lut[4'b0000] = 1'b0;
        lut[4'b0001] = 1'b1;
        lut[4'b0010] = 1'b0;
        lut[4'b0011] = 1'b1;
        lut[4'b0100] = 1'b0;
        lut[4'b0101] = 1'b1;
        lut[4'b0110] = 1'b0;
        lut[4'b0111] = 1'b1;
        lut[4'b1000] = 1'b1;
        lut[4'b1001] = 1'b0;
        lut[4'b1010] = 1'b1;
        lut[4'b1011] = 1'b0;
        lut[4'b1100] = 1'b1;
        lut[4'b1101] = 1'b0;
        lut[4'b1110] = 1'b1;
        lut[4'b1111] = 1'b0;
    end
    
    always @(*) begin
        out = lut[addr];
    end
endmodule

// 输入组合子模块
module input_combiner(
    input a, b, c, d,
    output [3:0] combined
);
    assign combined = {a, b, c, d};
endmodule

// 顶层模块
module complex_expr(
    input a, b, c, d,
    output y
);
    wire [3:0] lut_addr;
    
    input_combiner u_input_combiner(
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .combined(lut_addr)
    );
    
    lut_4bit u_lut(
        .addr(lut_addr),
        .out(y)
    );
endmodule