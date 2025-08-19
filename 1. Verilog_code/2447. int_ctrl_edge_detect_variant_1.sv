//SystemVerilog
module int_ctrl_edge_detect #(parameter WIDTH=8)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_int,
    input  wire             valid_in,
    output wire [WIDTH-1:0] edge_out,
    output wire             valid_out
);
    // 内部连线
    wire [WIDTH-1:0] sync_data_stage1;
    wire             valid_stage1;
    wire [WIDTH-1:0] sync_data_stage2;
    wire [WIDTH-1:0] prev_data_stage2;
    wire             valid_stage2;

    // 子模块实例化
    input_synchronizer #(
        .WIDTH(WIDTH)
    ) u_input_synchronizer (
        .clk        (clk),
        .rst_n      (rst_n),
        .async_in   (async_int),
        .valid_in   (valid_in),
        .sync_out   (sync_data_stage1),
        .valid_out  (valid_stage1)
    );

    data_pipeline #(
        .WIDTH(WIDTH)
    ) u_data_pipeline (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (sync_data_stage1),
        .valid_in   (valid_stage1),
        .curr_data  (sync_data_stage2),
        .prev_data  (prev_data_stage2),
        .valid_out  (valid_stage2)
    );

    edge_detector #(
        .WIDTH(WIDTH)
    ) u_edge_detector (
        .curr_data  (sync_data_stage2),
        .prev_data  (prev_data_stage2),
        .valid_in   (valid_stage2),
        .edge_out   (edge_out),
        .valid_out  (valid_out)
    );

endmodule

// 子模块1: 输入同步器
module input_synchronizer #(parameter WIDTH=8)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_in,
    input  wire             valid_in,
    output reg  [WIDTH-1:0] sync_out,
    output reg              valid_out
);
    // 流水线第一级：同步输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            sync_out  <= async_in;
            valid_out <= valid_in;
        end
    end
endmodule

// 子模块2: 数据流水线
module data_pipeline #(parameter WIDTH=8)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    input  wire             valid_in,
    output reg  [WIDTH-1:0] curr_data,
    output reg  [WIDTH-1:0] prev_data,
    output reg              valid_out
);
    // 流水线第二级：保存当前值和前一个值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_data <= {WIDTH{1'b0}};
            prev_data <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            curr_data <= data_in;
            prev_data <= curr_data;
            valid_out <= valid_in;
        end
    end
endmodule

// 子模块3: 边沿检测器
module edge_detector #(parameter WIDTH=8)(
    input  wire [WIDTH-1:0] curr_data,
    input  wire [WIDTH-1:0] prev_data,
    input  wire             valid_in,
    output wire [WIDTH-1:0] edge_out,
    output wire             valid_out
);
    // 上升沿检测逻辑
    assign edge_out = curr_data & ~prev_data;
    assign valid_out = valid_in;
endmodule