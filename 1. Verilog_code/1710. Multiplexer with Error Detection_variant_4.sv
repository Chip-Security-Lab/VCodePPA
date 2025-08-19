//SystemVerilog
// 顶层模块
module error_detect_mux(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input valid_a, valid_b, valid_c, valid_d,
    output [7:0] out_data,
    output error_flag
);
    // 内部信号
    wire [7:0] selected_data;
    wire selected_valid;

    // 子模块实例化
    input_selector selector_inst (
        .in_a(in_a),
        .in_b(in_b),
        .in_c(in_c),
        .in_d(in_d),
        .valid_a(valid_a),
        .valid_b(valid_b),
        .valid_c(valid_c),
        .valid_d(valid_d),
        .select(select),
        .selected_data(selected_data),
        .selected_valid(selected_valid)
    );

    error_detector error_det_inst (
        .data_in(selected_data),
        .valid_in(selected_valid),
        .data_out(out_data),
        .error_flag(error_flag)
    );
endmodule

// 输入选择器子模块
module input_selector(
    input [7:0] in_a, in_b, in_c, in_d,
    input valid_a, valid_b, valid_c, valid_d,
    input [1:0] select,
    output reg [7:0] selected_data,
    output reg selected_valid
);
    always @(*) begin
        case (select)
            2'b00: begin
                selected_data = in_a;
                selected_valid = valid_a;
            end
            2'b01: begin
                selected_data = in_b;
                selected_valid = valid_b;
            end
            2'b10: begin
                selected_data = in_c;
                selected_valid = valid_c;
            end
            2'b11: begin
                selected_data = in_d;
                selected_valid = valid_d;
            end
            default: begin
                selected_data = 8'h00;
                selected_valid = 1'b0;
            end
        endcase
    end
endmodule

// 错误检测器子模块
module error_detector(
    input [7:0] data_in,
    input valid_in,
    output reg [7:0] data_out,
    output reg error_flag
);
    always @(*) begin
        data_out = data_in;
        error_flag = !valid_in;
    end
endmodule