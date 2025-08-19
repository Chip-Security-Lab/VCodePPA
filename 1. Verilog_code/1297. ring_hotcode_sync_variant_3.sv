//SystemVerilog - IEEE 1364-2005
// 顶层模块 - 流水线版本
module ring_hotcode_sync (
    input  wire       clock,
    input  wire       sync_rst,
    output wire [3:0] cnt_reg
);
    // 流水线控制信号
    reg  valid_stage1, valid_stage2;
    
    // 流水线数据路径
    wire [3:0] next_cnt;
    wire [3:0] current_cnt;
    reg  [3:0] stage1_cnt;
    
    // 实例化子模块
    cnt_register cnt_register_inst (
        .clock      (clock),
        .sync_rst   (sync_rst),
        .next_cnt   (next_cnt),
        .current_cnt(current_cnt),
        .valid_in   (valid_stage2)
    );

    cnt_logic cnt_logic_inst (
        .current_cnt(current_cnt),
        .next_cnt   (next_cnt)
    );
    
    // 流水线控制逻辑
    always @(posedge clock) begin
        if (sync_rst) begin
            valid_stage1 <= 1'b1;
            valid_stage2 <= 1'b0;
            stage1_cnt <= 4'b0001;
        end
        else begin
            valid_stage1 <= 1'b1;
            valid_stage2 <= valid_stage1;
            stage1_cnt <= next_cnt;
        end
    end

    // 输出赋值
    assign cnt_reg = current_cnt;

endmodule

// 计数器寄存器子模块，负责存储和更新计数值
module cnt_register (
    input  wire       clock,
    input  wire       sync_rst,
    input  wire [3:0] next_cnt,
    input  wire       valid_in,
    output reg  [3:0] current_cnt
);
    always @(posedge clock) begin
        if (sync_rst)
            current_cnt <= 4'b0001;
        else if (valid_in)
            current_cnt <= next_cnt;
    end
endmodule

// 计数逻辑子模块，负责计算下一个计数值
module cnt_logic (
    input  wire [3:0] current_cnt,
    output wire [3:0] next_cnt
);
    // 环形热码计数逻辑：右移一位并将最低位移到最高位
    assign next_cnt = {current_cnt[0], current_cnt[3:1]};
endmodule