//SystemVerilog
module usb_split_handler(
    input wire clk,
    input wire reset,
    input wire [3:0] hub_addr,
    input wire [3:0] port_num,
    input wire [7:0] transaction_type,
    input wire start_split,
    input wire complete_split,
    output reg [15:0] split_token,
    output reg token_valid,
    output reg [1:0] state
);
    // 状态定义
    localparam IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, COMPLETE = 2'b11;
    
    // 流水线阶段寄存器
    reg [3:0] hub_addr_stage1, hub_addr_stage2;
    reg [3:0] port_num_stage1, port_num_stage2;
    reg [7:0] transaction_type_stage1, transaction_type_stage2;
    reg start_split_stage1, start_split_stage2;
    reg complete_split_stage1, complete_split_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg [1:0] state_stage1;
    
    // 中间计算结果
    reg [7:0] command_byte_stage1, command_byte_stage2;
    reg [15:0] token_stage1, token_stage2;
    
    // 第一级流水线 - 输入寄存和命令检测
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hub_addr_stage1 <= 4'h0;
            port_num_stage1 <= 4'h0;
            transaction_type_stage1 <= 8'h0;
            start_split_stage1 <= 1'b0;
            complete_split_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            state_stage1 <= IDLE;
        end else begin
            hub_addr_stage1 <= hub_addr;
            port_num_stage1 <= port_num;
            transaction_type_stage1 <= transaction_type;
            start_split_stage1 <= start_split;
            complete_split_stage1 <= complete_split;
            
            // 状态转移逻辑
            case (state)
                IDLE: begin
                    if (start_split) begin
                        state_stage1 <= START;
                        valid_stage1 <= 1'b1;
                    end else if (complete_split) begin
                        state_stage1 <= COMPLETE;
                        valid_stage1 <= 1'b1;
                    end else begin
                        state_stage1 <= IDLE;
                        valid_stage1 <= 1'b0;
                    end
                end
                START: begin
                    state_stage1 <= WAIT;
                    valid_stage1 <= 1'b0;
                end
                WAIT: begin
                    if (complete_split) begin
                        state_stage1 <= COMPLETE;
                        valid_stage1 <= 1'b1;
                    end else begin
                        state_stage1 <= WAIT;
                        valid_stage1 <= 1'b0;
                    end
                end
                COMPLETE: begin
                    state_stage1 <= IDLE;
                    valid_stage1 <= 1'b0;
                end
                default: begin
                    state_stage1 <= IDLE;
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 第一级流水线 - 命令字节计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            command_byte_stage1 <= 8'h0;
        end else begin
            if ((state == IDLE && start_split) || 
                (state == WAIT && complete_split) || 
                (state == IDLE && complete_split)) begin
                
                if (complete_split || (state == WAIT)) begin
                    // Complete split command
                    command_byte_stage1 <= {transaction_type[1:0], 2'b10, port_num};
                end else begin
                    // Start split command
                    command_byte_stage1 <= {transaction_type[1:0], 2'b00, port_num};
                end
            end
        end
    end
    
    // 第二级流水线 - 传递数据和构建令牌
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hub_addr_stage2 <= 4'h0;
            command_byte_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            token_stage2 <= 16'h0000;
        end else begin
            hub_addr_stage2 <= hub_addr_stage1;
            command_byte_stage2 <= command_byte_stage1;
            valid_stage2 <= valid_stage1;
            
            // 令牌构建
            if (valid_stage1) begin
                token_stage2 <= {hub_addr_stage1, command_byte_stage1, 4'b0000}; // CRC5 omitted
            end
        end
    end
    
    // 输出阶段 - 更新状态和输出
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            token_valid <= 1'b0;
            split_token <= 16'h0000;
        end else begin
            state <= state_stage1;
            token_valid <= valid_stage2;
            
            if (valid_stage2) begin
                split_token <= token_stage2;
            end
        end
    end
endmodule