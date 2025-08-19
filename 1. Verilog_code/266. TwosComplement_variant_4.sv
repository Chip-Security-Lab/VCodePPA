//SystemVerilog
module TwosComplement (
    input  wire        clk,         // 时钟信号
    input  wire        rst_n,       // 复位信号，低电平有效
    input  wire        data_valid,  // 输入数据有效信号
    input  wire signed [15:0] number,      // 输入数据
    output wire        result_valid,       // 结果有效信号
    output wire [15:0] complement         // 补码结果
);

    // 内部连线定义
    wire        stage1_valid;      // 第一级流水线有效信号
    wire [15:0] inverted_data;     // 存储取反后的数据
    wire        stage2_valid;      // 第二级流水线有效信号
    wire [15:0] add_one_result;    // 存储加1后的结果

    // 实例化数据取反模块
    InvertStage invert_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_valid (data_valid),
        .number     (number),
        .valid_out  (stage1_valid),
        .data_out   (inverted_data)
    );

    // 实例化加1操作模块
    AddOneStage add_one_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (stage1_valid),
        .data_in    (inverted_data),
        .valid_out  (stage2_valid),
        .data_out   (add_one_result)
    );

    // 实例化输出寄存模块
    OutputStage output_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (stage2_valid),
        .data_in    (add_one_result),
        .valid_out  (result_valid),
        .data_out   (complement)
    );

endmodule

// 第一阶段模块：数据取反
module InvertStage #(
    parameter WIDTH = 16
)(
    input  wire             clk,        // 时钟信号
    input  wire             rst_n,      // 复位信号
    input  wire             data_valid, // 输入数据有效信号
    input  wire [WIDTH-1:0] number,     // 输入数据
    output reg              valid_out,  // 输出有效信号
    output reg  [WIDTH-1:0] data_out    // 输出数据
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (data_valid) begin
                data_out  <= ~number;  // 取反操作
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// 第二阶段模块：加1操作
module AddOneStage #(
    parameter WIDTH = 16
)(
    input  wire             clk,       // 时钟信号
    input  wire             rst_n,     // 复位信号
    input  wire             valid_in,  // 输入有效信号
    input  wire [WIDTH-1:0] data_in,   // 输入数据
    output reg              valid_out, // 输出有效信号
    output reg  [WIDTH-1:0] data_out   // 输出数据
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                data_out  <= data_in + {{(WIDTH-1){1'b0}}, 1'b1};  // 加1操作
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// 输出阶段模块：寄存结果
module OutputStage #(
    parameter WIDTH = 16
)(
    input  wire             clk,       // 时钟信号
    input  wire             rst_n,     // 复位信号
    input  wire             valid_in,  // 输入有效信号
    input  wire [WIDTH-1:0] data_in,   // 输入数据
    output reg              valid_out, // 输出有效信号
    output reg  [WIDTH-1:0] data_out   // 输出数据
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_in;
            valid_out <= valid_in;
        end
    end

endmodule