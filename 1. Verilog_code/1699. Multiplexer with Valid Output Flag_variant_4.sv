//SystemVerilog
module mux_with_valid #(
    parameter W = 32
)(
    input [W-1:0] in_data[0:3],
    input [1:0] select,
    input in_valid[0:3],
    output [W-1:0] out_data,
    output out_valid
);
    // 使用条件反相减法器优化选择逻辑
    wire [W-1:0] data_temp;
    wire valid_temp;

    // 生成选择信号的条件逻辑
    assign data_temp = (select == 2'b00) ? in_data[0] :
                       (select == 2'b01) ? in_data[1] :
                       (select == 2'b10) ? in_data[2] :
                       (select == 2'b11) ? in_data[3] : {W{1'b0}};

    assign valid_temp = (select == 2'b00) ? in_valid[0] :
                        (select == 2'b01) ? in_valid[1] :
                        (select == 2'b10) ? in_valid[2] :
                        (select == 2'b11) ? in_valid[3] : 1'b0;

    // 输出结果
    assign out_data = data_temp;
    assign out_valid = valid_temp;
endmodule