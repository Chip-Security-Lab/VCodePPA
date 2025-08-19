//SystemVerilog
module Comparator_TriState #(parameter WIDTH = 8) (
    input              en,
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output tri         equal
);
    wire [WIDTH-1:0] complement_src2;
    wire [WIDTH-1:0] sub_result;
    wire zero_flag;
    reg equal_reg;
    
    // 实例化补码计算模块
    Complement_Calculator #(WIDTH) comp_calc (
        .src(src2),
        .complement(complement_src2)
    );
    
    // 实例化减法器模块
    Subtractor #(WIDTH) sub (
        .src1(src1),
        .src2(complement_src2),
        .result(sub_result)
    );
    
    // 实例化零检测模块
    Zero_Detector #(WIDTH) zero_det (
        .data(sub_result),
        .is_zero(zero_flag)
    );
    
    // 实例化三态输出控制模块
    TriState_Output tri_out (
        .en(en),
        .data(zero_flag),
        .out(equal_reg)
    );
    
    assign equal = equal_reg;
endmodule

module Complement_Calculator #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] src,
    output [WIDTH-1:0] complement
);
    assign complement = ~src + 1'b1;
endmodule

module Subtractor #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output [WIDTH-1:0] result
);
    assign result = src1 + src2;
endmodule

module Zero_Detector #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data,
    output is_zero
);
    assign is_zero = (data == {WIDTH{1'b0}});
endmodule

module TriState_Output (
    input  en,
    input  data,
    output reg out
);
    always @(*) begin
        if (en) begin
            out = data;
        end
        else begin
            out = 1'bz;
        end
    end
endmodule