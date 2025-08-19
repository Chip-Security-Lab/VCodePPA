//SystemVerilog
module width_expander #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32 // 必须是IN_WIDTH的整数倍
)(
    input clk,
    input rst,
    input valid_in,
    input [IN_WIDTH-1:0] data_in,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg valid_out
);
    // 计算输入到输出的宽度比
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    localparam COUNT_WIDTH = (RATIO > 1) ? $clog2(RATIO) : 1;

    reg [COUNT_WIDTH-1:0] input_count;
    reg [OUT_WIDTH-1:0] shift_buffer;

    wire input_count_last = (input_count == (RATIO-1));
    wire input_count_zero = (input_count == {COUNT_WIDTH{1'b0}});

    // 计数器与数据缓冲区管理逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            input_count <= {COUNT_WIDTH{1'b0}};
            shift_buffer <= {OUT_WIDTH{1'b0}};
        end else if (valid_in) begin
            shift_buffer <= {shift_buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
            input_count <= input_count_last ? {COUNT_WIDTH{1'b0}} : (input_count + {{(COUNT_WIDTH-1){1'b0}}, 1'b1});
        end
    end

    // 数据输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {OUT_WIDTH{1'b0}};
        end else if (valid_in && input_count_last) begin
            data_out <= {shift_buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
        end
    end

    // 有效信号输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in && input_count_last;
        end
    end

endmodule