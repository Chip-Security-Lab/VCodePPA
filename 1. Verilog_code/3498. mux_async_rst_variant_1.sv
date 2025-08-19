//SystemVerilog
module mux_async_rst #(
    parameter WIDTH = 8
)(
    input  wire             clk,       // 时钟信号
    input  wire             rst,       // 异步复位信号
    input  wire             sel,       // 选择信号
    input  wire [WIDTH-1:0] data_a,    // 输入数据通道A
    input  wire [WIDTH-1:0] data_b,    // 输入数据通道B
    output wire [WIDTH-1:0] data_out   // 输出数据
);
    // 内部连线，用于模块间通信
    wire [WIDTH-1:0] data_a_buf, data_b_buf;
    wire             sel_buf;
    wire [WIDTH-1:0] selected_data;

    // 实例化输入缓冲模块
    input_buffer #(
        .WIDTH(WIDTH)
    ) u_input_buffer (
        .clk      (clk),
        .rst      (rst),
        .data_a_in(data_a),
        .data_b_in(data_b),
        .sel_in   (sel),
        .data_a_out(data_a_buf),
        .data_b_out(data_b_buf),
        .sel_out   (sel_buf)
    );

    // 实例化选择器模块
    data_selector #(
        .WIDTH(WIDTH)
    ) u_data_selector (
        .clk        (clk),
        .rst        (rst),
        .sel        (sel_buf),
        .data_a     (data_a_buf),
        .data_b     (data_b_buf),
        .selected_data(selected_data)
    );

    // 实例化输出缓冲模块
    output_buffer #(
        .WIDTH(WIDTH)
    ) u_output_buffer (
        .clk      (clk),
        .rst      (rst),
        .data_in  (selected_data),
        .data_out (data_out)
    );

endmodule

// 输入缓冲子模块 - 第一级流水线
module input_buffer #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] data_a_in,
    input  wire [WIDTH-1:0] data_b_in,
    input  wire             sel_in,
    output reg  [WIDTH-1:0] data_a_out,
    output reg  [WIDTH-1:0] data_b_out,
    output reg              sel_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_a_out <= {WIDTH{1'b0}};
            data_b_out <= {WIDTH{1'b0}};
            sel_out    <= 1'b0;
        end else begin
            data_a_out <= data_a_in;
            data_b_out <= data_b_in;
            sel_out    <= sel_in;
        end
    end
endmodule

// 数据选择器子模块 - 第二级流水线
module data_selector #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             sel,
    input  wire [WIDTH-1:0] data_a,
    input  wire [WIDTH-1:0] data_b,
    output reg  [WIDTH-1:0] selected_data
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            selected_data <= {WIDTH{1'b0}};
        end else begin
            selected_data <= sel ? data_a : data_b;
        end
    end
endmodule

// 输出缓冲子模块 - 第三级流水线
module output_buffer #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end
endmodule