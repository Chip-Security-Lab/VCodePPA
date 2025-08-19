//SystemVerilog
//IEEE 1364-2005 Verilog标准
module int_ctrl_edge_detect #(parameter WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] async_int,
    input wire valid_in,
    output wire valid_out,
    output wire [WIDTH-1:0] edge_out
);

    // 第一级流水线信号
    reg [WIDTH-1:0] sync_reg_stage1;
    reg [WIDTH-1:0] prev_reg_stage1;
    reg valid_stage1;
    reg [WIDTH-1:0] edge_detect_stage1;

    // 第二级流水线信号
    reg [WIDTH-1:0] edge_out_stage2;
    reg valid_stage2;

    // 第一级流水线 - 信号同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg_stage1 <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            sync_reg_stage1 <= async_int;
        end
    end

    // 第一级流水线 - 保存前一周期值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_reg_stage1 <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            prev_reg_stage1 <= sync_reg_stage1;
        end
    end

    // 第一级流水线 - 边沿检测计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detect_stage1 <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            edge_detect_stage1 <= sync_reg_stage1 & ~prev_reg_stage1;
        end
    end

    // 第一级流水线 - 有效信号处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线 - 边沿输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_out_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            edge_out_stage2 <= edge_detect_stage1;
        end
    end

    // 第二级流水线 - 有效信号输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出赋值
    assign edge_out = edge_out_stage2;
    assign valid_out = valid_stage2;

endmodule