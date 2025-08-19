//SystemVerilog
module status_sampling_ismu #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [WIDTH-1:0]     int_raw,
    input                  sample_en,
    output reg [WIDTH-1:0] int_status,
    output reg             status_valid
);

    // 流水线寄存器 - 捕获的中断信号
    reg [WIDTH-1:0] int_raw_r;
    reg [WIDTH-1:0] int_captured;
    // 采样控制信号流水线寄存器
    reg             sample_en_r;
    reg             sample_en_r2;

    // 前向重定时：直接寄存输入信号
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_raw_r   <= {WIDTH{1'b0}};
            sample_en_r <= 1'b0;
        end else begin
            int_raw_r   <= int_raw;
            sample_en_r <= sample_en;
        end
    end

    // 第二级流水线
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_captured <= {WIDTH{1'b0}};
            sample_en_r2 <= 1'b0;
        end else begin
            int_captured <= int_raw_r;
            sample_en_r2 <= sample_en_r;
        end
    end

    // 第三级流水线：状态更新和有效信号生成
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_status   <= {WIDTH{1'b0}};
            status_valid <= 1'b0;
        end else begin
            if (sample_en_r2) begin
                int_status   <= int_captured;
                status_valid <= 1'b1;
            end else begin
                status_valid <= 1'b0;
            end
        end
    end

endmodule