//SystemVerilog
// 顶层模块
module sync_bus_bridge #(parameter DWIDTH=32, AWIDTH=8) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr, dst_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid, dst_ready,
    output [DWIDTH-1:0] dst_data,
    output src_ready, dst_valid
);

    // 内部信号
    wire data_valid_stage1, data_valid_stage2;
    wire data_ready_stage1, data_ready_stage2;
    wire [DWIDTH-1:0] data_out_stage1, data_out_stage2;

    // 实例化数据路径模块
    data_path #(
        .DWIDTH(DWIDTH)
    ) data_path_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .src_data(src_data),
        .data_valid(data_valid_stage1),
        .data_ready(data_ready_stage1),
        .data_out(data_out_stage1)
    );

    // 添加流水线寄存器
    reg [DWIDTH-1:0] data_out_reg;
    reg data_valid_reg, data_ready_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_reg <= 0;
            data_valid_reg <= 0;
            data_ready_reg <= 1;
        end else begin
            data_out_reg <= data_out_stage1;
            data_valid_reg <= data_valid_stage1;
            data_ready_reg <= data_ready_stage1;
        end
    end

    // 实例化第二阶段数据路径
    data_path #(
        .DWIDTH(DWIDTH)
    ) data_path_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .src_data(data_out_reg),
        .data_valid(data_valid_reg),
        .data_ready(data_ready_reg),
        .data_out(data_out_stage2)
    );

    // 实例化控制逻辑模块
    control_logic control_logic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid(src_valid),
        .dst_ready(dst_ready),
        .data_valid(data_valid_stage1),
        .data_ready(data_ready_stage1),
        .src_ready(src_ready),
        .dst_valid(dst_valid)
    );

    // 输出赋值
    assign dst_data = data_out_stage2;

endmodule

// 数据路径模块
module data_path #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] src_data,
    input data_valid,
    input data_ready,
    output reg [DWIDTH-1:0] data_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= 0;
        end else if (data_valid && data_ready) begin
            data_out <= src_data;
        end
    end

endmodule

// 控制逻辑模块
module control_logic (
    input clk, rst_n,
    input src_valid, dst_ready,
    output reg data_valid,
    output reg data_ready,
    output reg src_ready,
    output reg dst_valid
);

    always @(posedge clk) begin
        if (!rst_n) begin
            dst_valid <= 0;
            src_ready <= 1;
            data_valid <= 0;
            data_ready <= 1;
        end else begin
            if (src_valid && src_ready) begin
                dst_valid <= 1;
                src_ready <= 0;
                data_valid <= 1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 0;
                src_ready <= 1;
                data_valid <= 0;
            end
        end
    end

endmodule