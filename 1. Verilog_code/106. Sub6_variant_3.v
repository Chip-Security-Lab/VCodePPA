module Sub6(
    input [7:0] a,
    input [7:0] b, 
    input en,
    output [7:0] res
);

    // 实例化基拉斯基乘法器子模块
    karatsuba_multiplier mult_inst(
        .a(a),
        .b(b),
        .en(en),
        .res(res)
    );

endmodule

module karatsuba_multiplier(
    input [7:0] a,
    input [7:0] b,
    input en,
    output reg [7:0] res
);

    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];
    
    wire [7:0] z0, z1, z2;
    wire [7:0] temp1, temp2;
    
    // 计算三个部分积
    assign z0 = a_low * b_low;
    assign z1 = (a_high + a_low) * (b_high + b_low);
    assign z2 = a_high * b_high;
    
    // 组合最终结果
    assign temp1 = z2 << 8;
    assign temp2 = (z1 - z2 - z0) << 4;
    
    always @(*) begin
        res = en ? (temp1 + temp2 + z0) : 0;
    end

endmodule