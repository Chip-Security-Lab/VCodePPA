//SystemVerilog
module ring_hotcode_sync (
    input wire clock,
    input wire sync_rst,
    input wire valid_in,      // 输入有效信号
    output wire valid_out,    // 输出有效信号
    output wire [3:0] cnt_out // 计数器输出
);

    // 流水线阶段寄存器
    reg [3:0] cnt_stage1, cnt_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一阶段：初始计算和输入处理
    always @(posedge clock) begin
        if (sync_rst) begin
            cnt_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end else begin
            case ({valid_in, valid_stage1})
                2'b10, 2'b11: begin  // valid_in = 1，优先级高
                    cnt_stage1 <= 4'b0001;   // 在有效输入时初始化
                    valid_stage1 <= 1'b1;
                end
                2'b01: begin  // valid_stage1 = 1, valid_in = 0
                    cnt_stage1 <= {cnt_stage1[0], cnt_stage1[3:1]}; // 循环移位
                    valid_stage1 <= 1'b1;
                end
                2'b00: begin  // 两者都为0
                    cnt_stage1 <= cnt_stage1;  // 保持当前值
                    valid_stage1 <= 1'b0;
                end
                default: begin  // 冗余情况处理
                    cnt_stage1 <= cnt_stage1;
                    valid_stage1 <= valid_stage1;
                end
            endcase
        end
    end
    
    // 第二阶段：中间处理
    always @(posedge clock) begin
        if (sync_rst) begin
            cnt_stage2 <= 4'b0001;
            valid_stage2 <= 1'b0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign cnt_out = cnt_stage2;
    assign valid_out = valid_stage2;

endmodule