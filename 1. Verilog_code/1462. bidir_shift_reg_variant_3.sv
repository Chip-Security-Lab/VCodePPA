//SystemVerilog
module bidir_shift_reg(
    input clock, clear,
    input [7:0] p_data,
    input load, shift, dir, s_in,
    output reg [7:0] q
);
    // 优化缓冲逻辑以减少关键路径延迟
    reg load_ff, shift_ff, dir_ff;
    reg s_in_ff;
    reg [7:0] p_data_ff;
    
    // 分离控制信号和数据路径的缓冲逻辑
    always @(posedge clock) begin
        {load_ff, shift_ff, dir_ff, s_in_ff} <= {load, shift, dir, s_in};
        p_data_ff <= p_data;
    end
    
    // 主要寄存器逻辑 - 优化条件检查顺序并合并相关操作
    always @(posedge clock) begin
        if (clear) begin
            q <= 8'b0;
        end
        else begin
            // 优先级控制结构优化
            case ({load_ff, shift_ff})
                2'b10:   q <= p_data_ff;                          // 载入操作
                2'b01:   q <= dir_ff ? {s_in_ff, q[7:1]} :        // 右移
                                       {q[6:0], s_in_ff};         // 左移
                default: q <= q;                                  // 保持原值
            endcase
        end
    end
endmodule