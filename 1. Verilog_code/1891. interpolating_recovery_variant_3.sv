//SystemVerilog
module interpolating_recovery #(
    parameter WIDTH = 12
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] sample_a,
    input wire [WIDTH-1:0] sample_b,
    output reg [WIDTH-1:0] interpolated,
    output reg valid_out,
    output wire ready_in
);
    // 定义流水线寄存器
    reg [WIDTH-1:0] sample_a_stage1, sample_b_stage1;
    reg [WIDTH-1:0] sum_stage2;
    reg valid_stage1, valid_stage2;

    // 反压信号逻辑 - 始终准备接收新数据
    assign ready_in = 1'b1;

    // 第一级：拆分为独立的always块
    // 样本A寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_a_stage1 <= {WIDTH{1'b0}};
        end else begin
            sample_a_stage1 <= sample_a;
        end
    end

    // 样本B寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_b_stage1 <= {WIDTH{1'b0}};
        end else begin
            sample_b_stage1 <= sample_b;
        end
    end

    // 第一级有效信号寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end

    // 第二级：加法计算块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            sum_stage2 <= sample_a_stage1 + sample_b_stage1;
        end
    end

    // 第二级有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级：右移操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interpolated <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            interpolated <= sum_stage2 >> 1;
        end
    end

    // 第三级有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end
endmodule