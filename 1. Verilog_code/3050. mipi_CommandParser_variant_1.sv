//SystemVerilog
module MIPI_CommandParser #(
    parameter CMD_TABLE_SIZE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] cmd_byte,
    input wire cmd_valid,
    output reg [15:0] param_reg,
    output reg cmd_ready
);
    // 命令表定义
    reg [7:0] cmd_opcodes [0:CMD_TABLE_SIZE-1];
    reg [3:0] cmd_param_lens [0:CMD_TABLE_SIZE-1];
    
    // 初始化命令表
    initial begin
        // 示例命令
        cmd_opcodes[0] = 8'h01; cmd_param_lens[0] = 4'd2;
        cmd_opcodes[1] = 8'h02; cmd_param_lens[1] = 4'd1;
        // 填充其余命令表
        cmd_opcodes[2] = 8'h03; cmd_param_lens[2] = 4'd3;
        cmd_opcodes[3] = 8'h04; cmd_param_lens[3] = 4'd0;
        // ... 可以添加更多命令
    end
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [3:0] param_counter;
    reg [3:0] next_param_counter;
    reg [3:0] current_cmd_index;
    reg [3:0] next_cmd_index;
    reg cmd_found;
    reg next_cmd_found;
    reg [7:0] cmd_byte_reg;
    reg [7:0] next_cmd_byte_reg;
    reg [15:0] next_param_reg;
    reg next_cmd_ready;
    
    // 流水线寄存器
    reg [3:0] param_counter_pipe;
    reg [3:0] current_cmd_index_pipe;
    reg cmd_found_pipe;
    reg [7:0] cmd_byte_pipe;
    reg [15:0] param_reg_pipe;
    reg cmd_ready_pipe;
    
    // 借位减法器相关信号
    wire [3:0] param_counter_next;
    wire borrow;
    
    // 借位减法器实现
    assign {borrow, param_counter_next} = {1'b0, param_counter_pipe} - {4'b0, 1'b1};
    
    // 命令匹配逻辑
    wire cmd_match_0 = (cmd_byte_pipe == cmd_opcodes[0]);
    wire cmd_match_1 = (cmd_byte_pipe == cmd_opcodes[1]);
    wire cmd_match_2 = (cmd_byte_pipe == cmd_opcodes[2]);
    
    // 第一级流水线 - 状态和命令处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            param_counter <= 0;
            current_cmd_index <= 0;
            cmd_found <= 0;
            cmd_byte_reg <= 0;
            param_reg <= 0;
            cmd_ready <= 1;
        end else begin
            state <= next_state;
            param_counter <= next_param_counter;
            current_cmd_index <= next_cmd_index;
            cmd_found <= next_cmd_found;
            cmd_byte_reg <= next_cmd_byte_reg;
            param_reg <= next_param_reg;
            cmd_ready <= next_cmd_ready;
        end
    end
    
    // 第二级流水线 - 命令匹配和参数处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            param_counter_pipe <= 0;
            current_cmd_index_pipe <= 0;
            cmd_found_pipe <= 0;
            cmd_byte_pipe <= 0;
            param_reg_pipe <= 0;
            cmd_ready_pipe <= 1;
        end else begin
            param_counter_pipe <= param_counter;
            current_cmd_index_pipe <= current_cmd_index;
            cmd_found_pipe <= cmd_found;
            cmd_byte_pipe <= cmd_byte_reg;
            param_reg_pipe <= param_reg;
            cmd_ready_pipe <= cmd_ready;
        end
    end
    
    // 组合逻辑 - 下一状态计算
    always @(*) begin
        // 默认值
        next_state = state;
        next_param_counter = param_counter;
        next_cmd_index = current_cmd_index;
        next_cmd_found = cmd_found;
        next_cmd_byte_reg = cmd_byte_reg;
        next_param_reg = param_reg;
        next_cmd_ready = cmd_ready;
        
        case(state)
            0: begin // 空闲/命令搜索状态
                if (cmd_valid && cmd_ready) begin
                    next_cmd_byte_reg = cmd_byte;
                    next_cmd_found = 0;
                    next_cmd_index = 0;
                    
                    // 命令匹配逻辑移到流水线寄存器中
                    if (cmd_byte == cmd_opcodes[0]) begin
                        next_param_counter = cmd_param_lens[0];
                        next_cmd_index = 0;
                        next_cmd_found = 1;
                    end else if (cmd_byte == cmd_opcodes[1]) begin
                        next_param_counter = cmd_param_lens[1];
                        next_cmd_index = 1;
                        next_cmd_found = 1;
                    end else if (cmd_byte == cmd_opcodes[2]) begin
                        next_param_counter = cmd_param_lens[2];
                        next_cmd_index = 2;
                        next_cmd_found = 1;
                    end
                    
                    if (next_cmd_found) begin
                        next_state = 1;
                        next_cmd_ready = 0;
                    end
                end
            end
            
            1: begin // 参数处理状态
                if (cmd_valid) begin
                    next_param_reg = {param_reg[7:0], cmd_byte};
                    if (param_counter <= 1) begin
                        next_state = 2;
                        next_cmd_ready = 1;
                    end else begin
                        next_param_counter = param_counter_next;
                    end
                end
            end
            
            2: begin // 完成状态
                next_state = 0;
            end
            
            default: begin
                next_state = 0;
            end
        endcase
    end
endmodule