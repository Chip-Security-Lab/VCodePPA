//SystemVerilog
// 顶层模块
module Masked_XNOR (
    input        en_mask,
    input  [3:0] mask, data,
    output [3:0] res
);
    wire [3:0] masked_result;
    wire [3:0] bypass_result;
    
    // 子模块实例化
    XNOR_Operation xnor_op (
        .mask_data(mask),
        .input_data(data),
        .xnor_result(masked_result)
    );
    
    Bypass_Logic bypass_logic (
        .data_in(data),
        .data_out(bypass_result)
    );
    
    Output_Selector output_sel (
        .select_mask(en_mask),
        .masked_data(masked_result),
        .bypass_data(bypass_result),
        .final_result(res)
    );
    
endmodule

// XNOR操作子模块
module XNOR_Operation (
    input  [3:0] mask_data,
    input  [3:0] input_data,
    output [3:0] xnor_result
);
    assign xnor_result = ~(input_data ^ mask_data);
endmodule

// 数据直通子模块
module Bypass_Logic (
    input  [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = data_in;
endmodule

// 输出选择器子模块
module Output_Selector (
    input        select_mask,
    input  [3:0] masked_data,
    input  [3:0] bypass_data,
    output reg [3:0] final_result
);
    // 将条件运算符(? :)转换为if-else结构
    always @(*) begin
        if (select_mask) begin
            final_result = masked_data;
        end else begin
            final_result = bypass_data;
        end
    end
endmodule