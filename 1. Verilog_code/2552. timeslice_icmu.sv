module timeslice_icmu (
    input i_clk, i_rst_n,
    input [7:0] i_interrupts,
    input i_tick_1ms,
    output reg [2:0] o_int_id,
    output reg o_ctx_save,
    output reg o_int_active,
    input i_ctx_saved,
    input i_int_done
);
    reg [7:0] r_irq_pending;
    reg [7:0] r_irq_active;
    reg [7:0] r_timeslice [0:7];
    reg [7:0] r_elapsed;
    reg [2:0] r_current;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_irq_pending <= 8'h00;
            r_irq_active <= 8'h00;
            r_elapsed <= 8'h00;
            r_current <= 3'h0;
            o_int_id <= 3'h0;
            o_ctx_save <= 1'b0;
            o_int_active <= 1'b0;
            
            // 初始化默认时间片
            r_timeslice[0] <= 8'd10; // 10ms
            r_timeslice[1] <= 8'd20; // 20ms
            r_timeslice[2] <= 8'd5;  // 5ms
            r_timeslice[3] <= 8'd15; // 15ms
            r_timeslice[4] <= 8'd30; // 30ms
            r_timeslice[5] <= 8'd25; // 25ms
            r_timeslice[6] <= 8'd40; // 40ms
            r_timeslice[7] <= 8'd50; // 50ms
        end else begin
            // 捕获新中断
            r_irq_pending <= r_irq_pending | i_interrupts;
            
            // 定时器滴答处理
            if (i_tick_1ms && o_int_active && !o_ctx_save) begin
                r_elapsed <= r_elapsed + 8'd1;
                
                // 时间片到期？
                if (r_elapsed >= r_timeslice[r_current]) begin
                    o_ctx_save <= 1'b1;
                    r_elapsed <= 8'd0;
                end
            end
            
            // 中断调度
            if (!o_int_active && |r_irq_pending) begin
                // 查找下一个要服务的中断（轮询）
                r_current <= find_next(r_irq_pending, r_current);
                r_irq_active[r_current] <= 1'b1;
                r_irq_pending[r_current] <= 1'b0;
                o_int_id <= r_current;
                o_int_active <= 1'b1;
                r_elapsed <= 8'd0;
            end else if (o_ctx_save && i_ctx_saved) begin
                o_ctx_save <= 1'b0;
                
                // 如果有更多中断，继续处理下一个
                if (|r_irq_pending) begin
                    r_irq_active[r_current] <= 1'b0;
                    r_current <= find_next(r_irq_pending, r_current);
                    r_irq_active[r_current] <= 1'b1;
                    r_irq_pending[r_current] <= 1'b0;
                    o_int_id <= r_current;
                end
            end else if (i_int_done) begin
                r_irq_active[r_current] <= 1'b0;
                o_int_active <= 1'b0;
            end
        end
    end
    
    // 修复find_next函数以避免使用while循环
    function [2:0] find_next;
        input [7:0] pending;
        input [2:0] current;
        reg [2:0] next;
        integer i, count;
        begin
            next = (current + 3'd1) & 3'd7;
            count = 0;
            
            // 使用计数器限制循环
            for (i = 0; i < 8; i = i + 1) begin
                if (pending[next] || count >= 7) begin
                    break;
                end
                next = (next + 3'd1) & 3'd7;
                count = count + 1;
            end
            
            find_next = next;
        end
    endfunction
endmodule