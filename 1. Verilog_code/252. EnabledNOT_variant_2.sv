//SystemVerilog
// 顶层模块
module EnabledNOT(
    input en,
    input [3:0] src,
    output [3:0] result
);
    // 内部连线
    wire [3:0] inverted_data;
    
    // 子模块实例化
    DataInverter u_inverter (
        .data_in(src),
        .data_out(inverted_data)
    );
    
    OutputController u_output_ctrl (
        .enable(en),
        .data_in(inverted_data),
        .data_out(result)
    );
endmodule

// 数据反转子模块
module DataInverter(
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = ~data_in;
endmodule

// 输出控制子模块
module OutputController(
    input enable,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(*) begin
        data_out = enable ? data_in : 4'bzzzz;
    end
endmodule