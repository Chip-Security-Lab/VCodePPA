//SystemVerilog
module config_priority_ismu #(parameter N_SRC = 8)(
    input wire clock, resetn,
    input wire [N_SRC-1:0] interrupt_in,
    input wire [N_SRC-1:0] interrupt_mask,
    input wire [3*N_SRC-1:0] priority_config,
    output reg [2:0] highest_priority,
    output reg interrupt_valid
);
    // 存储每个中断源的优先级
    wire [2:0] curr_priority [N_SRC-1:0];
    // 存储有效中断源的标志
    wire [N_SRC-1:0] valid_interrupt;
    // 用于优先级比较的信号
    reg [2:0] max_prio_index;
    reg [2:0] max_prio_value;
    
    // 提取每个中断源的优先级配置
    genvar g;
    generate
        for (g = 0; g < N_SRC; g = g + 1) begin : gen_priority
            assign curr_priority[g] = priority_config[g*3+:3];
            // 标记有效的中断源（未被屏蔽且被触发）
            assign valid_interrupt[g] = interrupt_in[g] && !interrupt_mask[g];
        end
    endgenerate
    
    integer i;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            interrupt_valid <= 1'b0;
            highest_priority <= 3'd0;
            max_prio_value <= 3'd0;
            max_prio_index <= 3'd0;
        end else begin
            // 初始化
            max_prio_value = 3'd0;
            max_prio_index = 3'd0;
            interrupt_valid <= 1'b0;
            
            // 查找最高优先级中断
            for (i = 0; i < N_SRC; i = i + 1) begin
                // 扁平化条件：有效中断 && 优先级高于当前最高
                if (valid_interrupt[i] && 
                    $signed({curr_priority[i][2], curr_priority[i]}) > $signed({max_prio_value[2], max_prio_value})) begin
                    max_prio_value = curr_priority[i];
                    max_prio_index = i[2:0];
                    interrupt_valid <= 1'b1;
                end
            end
            
            // 更新输出
            if (interrupt_valid) begin
                highest_priority <= max_prio_index;
            end
        end
    end
endmodule