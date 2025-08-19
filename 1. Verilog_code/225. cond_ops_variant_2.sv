//SystemVerilog
module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    // 实例化加法运算模块
    adder_module add_inst (
        .data_in(val),
        .data_out(add_result)
    );
    
    // 实例化减法运算模块
    subtractor_module sub_inst (
        .data_in(val),
        .data_out(sub_result)
    );
    
    // 实例化选择器模块
    selector_module sel_inst (
        .add_value(add_result),
        .sub_value(sub_result),
        .sel(sel),
        .result(mux_out)
    );
    
    // 实例化取反模块
    inverter_module inv_inst (
        .data_in(val),
        .data_out(invert)
    );
    
    // 内部连线
    wire [3:0] add_result;
    wire [3:0] sub_result;
    
endmodule

// 加法运算模块 - 使用带状进位加法器
module adder_module (
    input [3:0] data_in,
    output [3:0] data_out
);
    wire [3:0] sum;
    wire [4:0] carry;
    
    // 生成进位
    assign carry[0] = 1'b0;
    assign carry[1] = (data_in[0] & 1'b1) | ((data_in[0] | 1'b1) & carry[0]);
    assign carry[2] = (data_in[1] & 1'b0) | ((data_in[1] | 1'b0) & carry[1]);
    assign carry[3] = (data_in[2] & 1'b1) | ((data_in[2] | 1'b1) & carry[2]);
    assign carry[4] = (data_in[3] & 1'b0) | ((data_in[3] | 1'b0) & carry[3]);
    
    // 计算和
    assign sum[0] = data_in[0] ^ 1'b1 ^ carry[0];
    assign sum[1] = data_in[1] ^ 1'b0 ^ carry[1];
    assign sum[2] = data_in[2] ^ 1'b1 ^ carry[2];
    assign sum[3] = data_in[3] ^ 1'b0 ^ carry[3];
    
    assign data_out = sum;
endmodule

// 减法运算模块
module subtractor_module (
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = data_in - 4'd3;
endmodule

// 选择器模块
module selector_module (
    input [3:0] add_value,
    input [3:0] sub_value,
    input sel,
    output reg [3:0] result
);
    always @(*) begin
        result = sel ? add_value : sub_value;
    end
endmodule

// 取反模块
module inverter_module (
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = ~data_in;
endmodule