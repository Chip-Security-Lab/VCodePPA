//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module counter_updown_top #(
    parameter WIDTH = 4
) (
    input clk, rst,
    input dir, en,
    output [WIDTH-1:0] cnt,
    // 流水线控制信号
    input valid_in,
    output valid_out,
    input ready_in,
    output ready_out
);

    // 内部连线
    wire stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    wire dir_stage1, en_stage1, dir_stage2;
    wire [WIDTH-1:0] cnt_stage2, intermediate_cnt, cnt_stage4;

    // 准备就绪逻辑子模块
    pipeline_ready_logic ready_logic_inst (
        .stage1_valid(stage1_valid),
        .stage2_valid(stage2_valid),
        .stage3_valid(stage3_valid),
        .ready_in(ready_in),
        .ready_out(ready_out)
    );

    // 流水线阶段1子模块 - 输入控制信号寄存
    pipeline_stage1 #(
        .WIDTH(WIDTH)
    ) stage1_inst (
        .clk(clk),
        .rst(rst),
        .dir(dir),
        .en(en),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .stage1_valid(stage1_valid),
        .dir_stage1(dir_stage1),
        .en_stage1(en_stage1)
    );

    // 流水线阶段2子模块 - 准备计算数据
    pipeline_stage2 #(
        .WIDTH(WIDTH)
    ) stage2_inst (
        .clk(clk),
        .rst(rst),
        .stage1_valid(stage1_valid),
        .en_stage1(en_stage1),
        .dir_stage1(dir_stage1),
        .cnt(cnt),
        .ready_in(ready_in),
        .stage2_valid(stage2_valid),
        .dir_stage2(dir_stage2),
        .cnt_stage2(cnt_stage2)
    );

    // 流水线阶段3子模块 - 执行计算操作
    pipeline_stage3 #(
        .WIDTH(WIDTH)
    ) stage3_inst (
        .clk(clk),
        .rst(rst),
        .stage2_valid(stage2_valid),
        .dir_stage2(dir_stage2),
        .cnt_stage2(cnt_stage2),
        .ready_in(ready_in),
        .stage3_valid(stage3_valid),
        .intermediate_cnt(intermediate_cnt)
    );

    // 流水线阶段4子模块 - 结果寄存和输出
    pipeline_stage4 #(
        .WIDTH(WIDTH)
    ) stage4_inst (
        .clk(clk),
        .rst(rst),
        .stage3_valid(stage3_valid),
        .intermediate_cnt(intermediate_cnt),
        .ready_in(ready_in),
        .stage4_valid(stage4_valid),
        .cnt_stage4(cnt_stage4),
        .cnt(cnt),
        .valid_out(valid_out)
    );

endmodule

// 准备就绪逻辑子模块
module pipeline_ready_logic (
    input stage1_valid,
    input stage2_valid,
    input stage3_valid,
    input ready_in,
    output ready_out
);
    
    assign ready_out = !stage1_valid || (ready_in && !stage2_valid) || (ready_in && !stage3_valid);

endmodule

// 流水线阶段1子模块 - 输入控制信号寄存
module pipeline_stage1 #(
    parameter WIDTH = 4
) (
    input clk, rst,
    input dir, en,
    input valid_in,
    input ready_out,
    output reg stage1_valid,
    output reg dir_stage1,
    output reg en_stage1
);

    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            dir_stage1 <= 1'b0;
            en_stage1 <= 1'b0;
        end else if (ready_out) begin
            stage1_valid <= valid_in;
            dir_stage1 <= dir;
            en_stage1 <= en;
        end
    end

endmodule

// 流水线阶段2子模块 - 准备计算数据
module pipeline_stage2 #(
    parameter WIDTH = 4
) (
    input clk, rst,
    input stage1_valid,
    input en_stage1,
    input dir_stage1,
    input [WIDTH-1:0] cnt,
    input ready_in,
    output reg stage2_valid,
    output reg dir_stage2,
    output reg [WIDTH-1:0] cnt_stage2
);

    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            dir_stage2 <= 1'b0;
            cnt_stage2 <= {WIDTH{1'b0}};
        end else if (ready_in || !stage2_valid) begin
            stage2_valid <= stage1_valid & en_stage1;
            dir_stage2 <= dir_stage1;
            cnt_stage2 <= cnt;
        end
    end

endmodule

// 流水线阶段3子模块 - 执行计算操作
module pipeline_stage3 #(
    parameter WIDTH = 4
) (
    input clk, rst,
    input stage2_valid,
    input dir_stage2,
    input [WIDTH-1:0] cnt_stage2,
    input ready_in,
    output reg stage3_valid,
    output reg [WIDTH-1:0] intermediate_cnt
);

    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 1'b0;
            intermediate_cnt <= {WIDTH{1'b0}};
        end else if (ready_in || !stage3_valid) begin
            stage3_valid <= stage2_valid;
            if (dir_stage2)
                intermediate_cnt <= cnt_stage2 + 1'b1;
            else
                intermediate_cnt <= cnt_stage2 - 1'b1;
        end
    end

endmodule

// 流水线阶段4子模块 - 结果寄存和输出
module pipeline_stage4 #(
    parameter WIDTH = 4
) (
    input clk, rst,
    input stage3_valid,
    input [WIDTH-1:0] intermediate_cnt,
    input ready_in,
    output reg stage4_valid,
    output reg [WIDTH-1:0] cnt_stage4,
    output reg [WIDTH-1:0] cnt,
    output reg valid_out
);

    // 结果寄存逻辑
    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 1'b0;
            cnt_stage4 <= {WIDTH{1'b0}};
        end else if (ready_in || !stage4_valid) begin
            stage4_valid <= stage3_valid;
            cnt_stage4 <= intermediate_cnt;
        end
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        if (rst) begin
            cnt <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (ready_in) begin
            cnt <= cnt_stage4;
            valid_out <= stage4_valid;
        end
    end

endmodule