//SystemVerilog
// 部分积生成模块
module partial_product_gen (
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] pp [0:3]
);
    always @(*) begin
        pp[0] = {4'b0, a} & {4'b0, b[0]};
        pp[1] = {3'b0, a, 1'b0} & {4'b0, b[1]};
        pp[2] = {2'b0, a, 2'b0} & {4'b0, b[2]};
        pp[3] = {1'b0, a, 3'b0} & {4'b0, b[3]};
    end
endmodule

// 第一级加法器模块
module adder_stage1 (
    input [7:0] pp [0:3],
    output reg [7:0] sum [0:1]
);
    always @(*) begin
        sum[0] = pp[0] + pp[1];
        sum[1] = pp[2] + pp[3];
    end
endmodule

// 第二级加法器模块
module adder_stage2 (
    input [7:0] sum [0:1],
    output reg [7:0] result
);
    always @(*) begin
        result = sum[0] + sum[1];
    end
endmodule

// 顶层模块
module rom_based_mult (
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] product
);
    wire [7:0] pp [0:3];
    wire [7:0] sum [0:1];
    
    partial_product_gen pp_gen (
        .a(addr_a),
        .b(addr_b),
        .pp(pp)
    );
    
    adder_stage1 add1 (
        .pp(pp),
        .sum(sum)
    );
    
    adder_stage2 add2 (
        .sum(sum),
        .result(product)
    );
endmodule