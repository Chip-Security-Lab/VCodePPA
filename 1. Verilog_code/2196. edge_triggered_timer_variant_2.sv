//SystemVerilog
module edge_triggered_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire reset_n,
    input wire trigger,
    input wire [WIDTH-1:0] duration,
    output reg timer_active,
    output reg timeout
);
    reg [WIDTH-1:0] counter;
    reg trigger_prev;
    
    // 移动边沿检测逻辑到寄存器前
    wire trigger_edge;
    
    // 预先计算比较结果
    wire counter_at_end;
    
    // 下一周期的信号预计算
    reg timer_active_next;
    reg timeout_next;
    reg [WIDTH-1:0] counter_next;
    
    // 边沿检测逻辑提前到组合逻辑部分
    assign trigger_edge = trigger & ~trigger_prev;
    
    // 计数器比较移到组合逻辑部分
    assign counter_at_end = (counter == duration - 1'b1);
    
    // 组合逻辑部分计算下一状态
    always @(*) begin
        // 默认保持当前值
        counter_next = counter;
        timer_active_next = timer_active;
        timeout_next = 1'b0; // 默认每周期复位
        
        case ({trigger_edge, timer_active})
            2'b10, 2'b11: begin // 优先处理触发边沿
                counter_next = {WIDTH{1'b0}};
                timer_active_next = 1'b1;
            end
            2'b01: begin // 计时器激活且无新触发
                if (counter_at_end) begin
                    timer_active_next = 1'b0;
                    timeout_next = 1'b1;
                end else begin
                    // 使用跳跃进位加法器实现加法
                    counter_next = carry_skip_adder(counter, {{(WIDTH-1){1'b0}}, 1'b1});
                end
            end
            default: begin // 2'b00，保持状态
                // 不执行任何操作
            end
        endcase
    end
    
    // 时序逻辑部分实现寄存器
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {WIDTH{1'b0}};
            timer_active <= 1'b0;
            timeout <= 1'b0;
            trigger_prev <= 1'b0;
        end else begin
            counter <= counter_next;
            timer_active <= timer_active_next;
            timeout <= timeout_next;
            trigger_prev <= trigger;
        end
    end
    
    // 跳跃进位加法器函数实现
    function [WIDTH-1:0] carry_skip_adder;
        input [WIDTH-1:0] a, b;
        reg [WIDTH-1:0] sum;
        reg [WIDTH:0] carry;
        reg [1:0] block_prop [1:0]; // 2个块的传播信号
        
        integer i, j;
        begin
            // 初始化进位
            carry[0] = 1'b0;
            
            // 计算4位一组的块进位传播信号
            for (j = 0; j < 2; j = j + 1) begin
                block_prop[j] = 1'b1; // 默认为传播状态
            end
            
            // 计算每个块内的传播信号
            for (i = 0; i < WIDTH; i = i + 1) begin
                j = i / 4; // 确定当前位属于哪个块
                if (j < 2) begin // 防止数组越界
                    block_prop[j] = block_prop[j] & (a[i] ^ b[i]);
                end
            end
            
            // 先计算每位的和和进位
            for (i = 0; i < WIDTH; i = i + 1) begin
                sum[i] = a[i] ^ b[i] ^ carry[i];
                carry[i+1] = (a[i] & b[i]) | ((a[i] ^ b[i]) & carry[i]);
            end
            
            // 跳跃进位逻辑
            for (j = 0; j < 1; j = j + 1) begin // 只处理第一个块，最后一个块不需要跳跃
                if (block_prop[j]) begin
                    // 如果整个块都是传播的，直接传递进位到下一个块
                    carry[(j+1)*4] = carry[j*4];
                    
                    // 重新计算受影响的位
                    for (i = j*4; i < (j+1)*4 && i < WIDTH; i = i + 1) begin
                        sum[i] = a[i] ^ b[i] ^ carry[i];
                        carry[i+1] = (a[i] & b[i]) | ((a[i] ^ b[i]) & carry[i]);
                    end
                end
            end
            
            carry_skip_adder = sum;
        end
    endfunction
endmodule