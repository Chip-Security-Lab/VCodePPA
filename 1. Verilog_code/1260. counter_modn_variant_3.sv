//SystemVerilog - IEEE 1364-2005
module counter_modn #(parameter N=10) (
    input  logic clk,
    input  logic rst,
    output logic [$clog2(N)-1:0] cnt
);

    // 流水线寄存器
    logic [$clog2(N)-1:0] cnt_stage1, cnt_stage2;
    logic stage1_valid, stage2_valid;
    logic stage1_reset, stage2_reset;
    logic stage1_max_reached, stage2_max_reached;

    // 第一级流水线：生成下一计数值和控制信号
    always_ff @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= '0;
            stage1_valid <= 1'b0;
            stage1_reset <= 1'b1;
            stage1_max_reached <= 1'b0;
        end
        else begin
            cnt_stage1 <= (cnt == N-1) ? '0 : cnt + 1'b1;
            stage1_valid <= 1'b1;
            stage1_reset <= 1'b0;
            stage1_max_reached <= (cnt == N-1);
        end
    end

    // 第二级流水线：处理计数值
    always_ff @(posedge clk) begin
        if (rst) begin
            cnt_stage2 <= '0;
            stage2_valid <= 1'b0;
            stage2_reset <= 1'b1;
            stage2_max_reached <= 1'b0;
        end
        else if (stage1_valid) begin
            cnt_stage2 <= cnt_stage1;
            stage2_valid <= stage1_valid;
            stage2_reset <= stage1_reset;
            stage2_max_reached <= stage1_max_reached;
        end
    end

    // 输出级：最终计数值输出
    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= '0;
        end
        else if (stage2_valid) begin
            cnt <= cnt_stage2;
        end
    end

endmodule