//SystemVerilog
// 顶层模块
module crossbar_fifo #(
    parameter DW = 8,     // 数据宽度
    parameter DEPTH = 4,  // FIFO深度
    parameter N = 2       // FIFO数量
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] push,
    input wire [N*DW-1:0] din,  // 打平的数组
    output wire [N*DW-1:0] dout  // 打平的数组
);

    // 内部信号定义
    wire [DW-1:0] fifo_data [0:N-1][0:DEPTH-1];
    wire [4:0] fifo_cnt [0:N-1];

    // 实例化FIFO控制器子模块
    fifo_controller #(
        .DW(DW),
        .DEPTH(DEPTH),
        .N(N)
    ) fifo_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .push(push),
        .din(din),
        .fifo_data(fifo_data),
        .fifo_cnt(fifo_cnt)
    );

    // 实例化输出选择器子模块
    output_selector #(
        .DW(DW),
        .N(N)
    ) out_sel_inst (
        .fifo_data(fifo_data[0][0]),  // 从第一个FIFO的第一个条目获取数据
        .dout(dout)
    );

endmodule

// FIFO控制器子模块
module fifo_controller #(
    parameter DW = 8,     // 数据宽度
    parameter DEPTH = 4,  // FIFO深度
    parameter N = 2       // FIFO数量
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] push,
    input wire [N*DW-1:0] din,
    output reg [DW-1:0] fifo_data [0:N-1][0:DEPTH-1],
    output reg [4:0] fifo_cnt [0:N-1]
);

    integer i;

    // 计数器复位逻辑 - 单独处理复位功能
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                fifo_cnt[i] <= 5'b0;
            end
        end
    end

    // FIFO数据写入逻辑 - 单独处理数据输入功能
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < N; i = i + 1) begin
                if (push[i] && fifo_cnt[i] < DEPTH) begin
                    fifo_data[i][fifo_cnt[i]] <= din[(i*DW) +: DW];
                end
            end
        end
    end

    // FIFO计数器更新逻辑 - 单独处理计数器增长功能
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < N; i = i + 1) begin
                if (push[i] && fifo_cnt[i] < DEPTH) begin
                    fifo_cnt[i] <= fifo_cnt[i] + 1'b1;
                end
            end
        end
    end

endmodule

// 输出选择器子模块
module output_selector #(
    parameter DW = 8,  // 数据宽度
    parameter N = 2    // 输出通道数
) (
    input wire [DW-1:0] fifo_data,  // 单个FIFO数据项
    output wire [N*DW-1:0] dout     // 所有输出通道
);

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin: gen_out
            assign dout[(g*DW) +: DW] = fifo_data;
        end
    endgenerate

endmodule