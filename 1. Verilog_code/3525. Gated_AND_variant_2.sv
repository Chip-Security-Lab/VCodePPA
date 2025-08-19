//SystemVerilog
// 顶层模块
module Gated_AND(
    input enable,
    input [3:0] vec_a, vec_b,
    output [3:0] res
);
    wire [7:0] mult_result;
    
    // 实例化乘法器子模块
    Multiplier multiplier_inst (
        .vec_a(vec_a),
        .vec_b(vec_b),
        .mult_result(mult_result)
    );
    
    // 实例化输出控制子模块
    OutputController output_ctrl_inst (
        .enable(enable),
        .mult_result(mult_result),
        .res(res)
    );
    
endmodule

// 乘法器子模块 - 负责执行乘法操作
module Multiplier(
    input [3:0] vec_a, vec_b,
    output reg [7:0] mult_result
);
    integer i;
    
    always @(*) begin
        mult_result = 8'b0;
        for (i = 0; i < 4; i = i + 1) begin
            if (vec_b[i]) begin
                mult_result = mult_result + (vec_a << i);
            end
        end
    end
endmodule

// 输出控制子模块 - 根据enable信号控制输出
module OutputController(
    input enable,
    input [7:0] mult_result,
    output reg [3:0] res
);
    always @(*) begin
        if (enable) begin
            res = mult_result[3:0];
        end else begin
            res = 4'b0000;
        end
    end
endmodule