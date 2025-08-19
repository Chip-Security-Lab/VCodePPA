//SystemVerilog
module int_ctrl_auto_clear #(
    parameter DW = 16
)(
    input wire clk,
    input wire rst_n,
    input wire ack,
    input wire [DW-1:0] int_src,
    input wire valid_in,
    output wire valid_out,
    output wire [DW-1:0] int_status
);

    // 流水线阶段1 - 注册输入和检测新中断
    reg [DW-1:0] int_src_stage1;
    reg [DW-1:0] int_status_stage1;
    reg ack_stage1;
    reg valid_stage1;

    // 流水线阶段2 - 计算更新的中断状态
    reg [DW-1:0] int_or_result_stage2;
    reg [DW-1:0] int_ack_mask_stage2;
    reg valid_stage2;

    // 流水线阶段3 - 最终中断状态
    reg [DW-1:0] int_status_stage3;
    reg valid_stage3;
    
    // 为ack_stage1添加缓冲寄存器以减少扇出负载
    reg ack_stage1_buf1, ack_stage1_buf2;
    
    // 阶段1: 注册输入信号
    always @(posedge clk) begin
        if (!rst_n) begin
            int_src_stage1 <= {DW{1'b0}};
            int_status_stage1 <= {DW{1'b0}};
            ack_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            int_src_stage1 <= int_src;
            int_status_stage1 <= int_status_stage3;  // 反馈最终结果
            ack_stage1 <= ack;
            valid_stage1 <= valid_in;
        end
    end
    
    // ack_stage1缓冲寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            ack_stage1_buf1 <= 1'b0;
            ack_stage1_buf2 <= 1'b0;
        end else begin
            ack_stage1_buf1 <= ack_stage1;
            ack_stage1_buf2 <= ack_stage1;
        end
    end

    // 阶段2: 计算逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            int_or_result_stage2 <= {DW{1'b0}};
            int_ack_mask_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            int_or_result_stage2 <= int_status_stage1 | int_src_stage1;
            // 使用ack_stage1的缓冲版本减轻负载
            int_ack_mask_stage2 <= ack_stage1_buf1 ? int_status_stage1 : {DW{1'b0}};
            valid_stage2 <= valid_stage1;
        end
    end

    // 阶段3: 最终结果计算
    always @(posedge clk) begin
        if (!rst_n) begin
            int_status_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            // 拆分计算以减少关键路径延迟
            reg [DW-1:0] inverted_mask;
            inverted_mask = ~int_ack_mask_stage2;
            int_status_stage3 <= int_or_result_stage2 & inverted_mask;
            valid_stage3 <= valid_stage2;
        end
    end

    // 输出连接
    assign int_status = int_status_stage3;
    assign valid_out = valid_stage3;

endmodule