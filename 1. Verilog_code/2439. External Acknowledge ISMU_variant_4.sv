//SystemVerilog
module ext_ack_ismu (
    input  wire       i_clk,      // 系统时钟
    input  wire       i_rst,      // 异步复位，高电平有效
    input  wire [3:0] i_int,      // 输入中断信号
    input  wire [3:0] i_mask,     // 中断屏蔽位
    input  wire       i_ext_ack,  // 外部中断确认信号
    input  wire [1:0] i_ack_id,   // 被确认的中断ID
    output reg        o_int_req,  // 中断请求输出
    output reg  [1:0] o_int_id    // 中断ID输出
);

    // ========== 阶段1: 中断捕获与屏蔽 ==========
    reg  [3:0] masked_int_r;      // 已屏蔽的中断信号寄存器
    wire [3:0] masked_int;        // 当前已屏蔽的中断信号
    
    assign masked_int = i_int & ~i_mask;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            masked_int_r <= 4'h0;
        end else begin
            masked_int_r <= masked_int;
        end
    end
    
    // ========== 阶段2: 中断确认处理 ==========
    reg  [3:0] pending;           // 待处理的中断
    reg  [3:0] clear_mask;        // 清除掩码
    reg        ext_ack_r;         // 寄存外部确认信号
    reg  [1:0] ack_id_r;          // 寄存确认ID
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            ext_ack_r <= 1'b0;
            ack_id_r  <= 2'b00;
        end else begin
            ext_ack_r <= i_ext_ack;
            ack_id_r  <= i_ack_id;
        end
    end
    
    // 生成清除掩码
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            clear_mask <= 4'h0;
        end else begin
            clear_mask <= ext_ack_r ? (4'h1 << ack_id_r) : 4'h0;
        end
    end
    
    // ========== 阶段3: 中断挂起管理 ==========
    reg  [3:0] active_ints;       // 当前活跃的中断
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pending <= 4'h0;
        end else begin
            pending <= (pending | masked_int_r) & ~clear_mask;
        end
    end
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            active_ints <= 4'h0;
        end else begin
            active_ints <= (pending | masked_int_r) & ~clear_mask;
        end
    end
    
    // ========== 阶段4: 中断请求生成 ==========
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_int_req <= 1'b0;
        end else begin
            o_int_req <= |active_ints;
        end
    end
    
    // ========== 阶段5: 中断优先级编码 ==========
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_int_id <= 2'h0;
        end else if (|active_ints) begin
            // 优先级编码器 - 优先选择最低位的中断
            casez (active_ints)
                4'b???1: o_int_id <= 2'd0;
                4'b??10: o_int_id <= 2'd1;
                4'b?100: o_int_id <= 2'd2;
                4'b1000: o_int_id <= 2'd3;
                default: o_int_id <= o_int_id; // 保持当前值
            endcase
        end
    end
    
endmodule