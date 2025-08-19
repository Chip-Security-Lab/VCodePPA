//SystemVerilog
module eth_backoff_timer (
    input wire clk,
    input wire rst_n,
    input wire start_backoff,
    input wire [3:0] collision_count,
    output reg backoff_active,
    output reg backoff_complete,
    output reg [15:0] backoff_time,
    output reg [15:0] current_time
);
    reg [15:0] slot_time;
    reg [7:0] random_seed;
    reg [15:0] max_slots;
    
    // 改进的LFSR实现 - 使用更简单的异或结构
    function [7:0] lfsr_next;
        input [7:0] current;
        begin
            lfsr_next = {current[6:0], current[7] ^ current[5] ^ current[3]};
        end
    endfunction
    
    // 状态控制 - 使用单热编码改善时序
    localparam IDLE     = 3'b001;
    localparam BACKOFF  = 3'b010;
    localparam COMPLETE = 3'b100;
    
    reg [2:0] state;
    
    // 优化的比较逻辑 - 使用差值比较而非直接比较
    wire backoff_reached;
    wire [16:0] time_diff; // 增加一位以检测溢出
    
    assign time_diff = {1'b0, backoff_time} - {1'b0, current_time};
    assign backoff_reached = time_diff[16]; // 当current_time >= backoff_time时为1
    
    // 优化的最大时隙计算 - 简化条件逻辑
    wire [15:0] calc_max_slots;
    wire use_max_value;
    
    assign use_max_value = (collision_count > 4'd10);
    assign calc_max_slots = use_max_value ? 16'd1023 : ((16'd1 << collision_count) - 16'd1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backoff_active <= 1'b0;
            backoff_complete <= 1'b0;
            backoff_time <= 16'd0;
            current_time <= 16'd0;
            slot_time <= 16'd512;
            random_seed <= 8'h45;
            max_slots <= 16'd0;
            state <= IDLE;
        end else begin
            // 默认值设置
            backoff_complete <= 1'b0;
            
            // LFSR种子更新 - 只在需要时更新以降低切换活动
            if (state == IDLE && start_backoff) begin
                random_seed <= lfsr_next(random_seed);
            end
            
            case (state)
                IDLE: begin
                    if (start_backoff) begin
                        // 使用预计算的最大时隙数
                        max_slots <= calc_max_slots;
                        
                        // 使用按位与操作限制随机值范围
                        backoff_time <= (random_seed & calc_max_slots) * slot_time;
                        current_time <= 16'd0;
                        backoff_active <= 1'b1;
                        state <= BACKOFF;
                    end
                end
                
                BACKOFF: begin
                    if (!backoff_reached) begin
                        // 增加计数器并保持状态
                        current_time <= current_time + 16'd1;
                    end else begin
                        // 退避完成
                        backoff_active <= 1'b0;
                        backoff_complete <= 1'b1;
                        state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    // 单周期完成状态
                    state <= IDLE;
                end
                
                default: begin
                    // 安全恢复
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule