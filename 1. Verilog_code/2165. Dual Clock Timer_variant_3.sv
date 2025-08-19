//SystemVerilog
module dual_clock_timer (
    input wire clk_fast, clk_slow, reset_n,
    
    // 输入接口 - Valid-Ready握手
    input wire [15:0] target,
    input wire target_valid,
    output wire target_ready,
    
    // 输出接口 - Valid-Ready握手
    output reg tick_out,
    output reg tick_valid,
    input wire tick_ready
);
    // 增加了预计算比较值的寄存器，减少关键路径
    reg [15:0] counter_fast;
    reg match_detected;
    reg [1:0] sync_reg;
    reg [15:0] target_minus_one;
    reg [15:0] target_reg;
    
    // 输入握手状态寄存器
    reg target_loaded;
    wire load_target;
    
    // 输出握手状态寄存器
    reg tick_handshake_done;
    
    // 添加缓冲寄存器以减少高扇出信号的延迟
    reg [15:0] counter_fast_buf1, counter_fast_buf2;
    reg [1:0] sync_reg_buf1, sync_reg_buf2;
    
    // 输入接口握手逻辑
    assign target_ready = ~target_loaded;
    assign load_target = target_valid & target_ready;
    
    // 快时钟域
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            counter_fast <= 16'h0000;
            match_detected <= 1'b0;
            target_minus_one <= 16'h0000;
            counter_fast_buf1 <= 16'h0000;
            counter_fast_buf2 <= 16'h0000;
            target_loaded <= 1'b0;
            target_reg <= 16'h0000;
        end else begin
            // 当有新的有效目标值时，装载目标值
            if (load_target) begin
                target_reg <= target;
                target_loaded <= 1'b1;
            end
            
            // 预计算目标值，避免每个周期都执行减法
            target_minus_one <= target_reg - 1'b1;
            
            // 计数器逻辑
            if (counter_fast == target_minus_one && target_loaded)
                counter_fast <= 16'h0000;
            else if (target_loaded)
                counter_fast <= counter_fast + 1'b1;
            
            // 为高扇出信号counter_fast添加缓冲寄存器
            counter_fast_buf1 <= counter_fast;
            counter_fast_buf2 <= counter_fast;
                
            // 优化比较操作，使用预先计算的值和缓冲后的counter
            match_detected <= (counter_fast_buf1 == target_minus_one) && target_loaded;
        end
    end
    
    // 慢时钟域，含同步器和边沿检测
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg <= 2'b00;
            sync_reg_buf1 <= 2'b00;
            sync_reg_buf2 <= 2'b00;
            tick_out <= 1'b0;
            tick_valid <= 1'b0;
            tick_handshake_done <= 1'b0;
        end else begin
            // 两级同步器减少亚稳态风险
            sync_reg <= {sync_reg[0], match_detected};
            
            // 为高扇出信号sync_reg添加缓冲寄存器
            sync_reg_buf1 <= sync_reg;
            sync_reg_buf2 <= sync_reg;
            
            // 上升沿检测逻辑，使用缓冲后的sync_reg
            tick_out <= sync_reg_buf1[0] & ~sync_reg_buf1[1];
            
            // 输出握手逻辑
            if (sync_reg_buf1[0] & ~sync_reg_buf1[1]) begin
                tick_valid <= 1'b1;
                tick_handshake_done <= 1'b0;
            end else if (tick_valid && tick_ready && !tick_handshake_done) begin
                tick_handshake_done <= 1'b1;
                tick_valid <= 1'b0;
            end
        end
    end
endmodule