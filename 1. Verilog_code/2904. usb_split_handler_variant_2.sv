//SystemVerilog
//IEEE 1364-2005
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
    
    // 内部信号
    reg [7:0] command_byte;
    reg [1:0] next_state;
    reg next_token_valid;
    
    // 重定时后的寄存器信号
    reg start_split_reg, complete_split_reg;
    reg [3:0] hub_addr_reg;
    reg [3:0] port_num_reg;
    reg [7:0] transaction_type_reg;
    reg [1:0] token_type_reg; // 0: start split, 1: complete split
    reg update_token_reg;
    reg [15:0] next_split_token;

    // 输入信号寄存
    always @(posedge clk) begin
        start_split_reg <= start_split;
        complete_split_reg <= complete_split;
        hub_addr_reg <= hub_addr;
        port_num_reg <= port_num;
        transaction_type_reg <= transaction_type;
    end

    // 状态转换逻辑 - 组合逻辑部分
    always @(*) begin
        // 默认值
        next_state = state;
        next_token_valid = 1'b0;
        update_token_reg = 1'b0;
        token_type_reg = 2'b00;
        
        case (state)
            IDLE: begin
                if (start_split_reg) begin
                    next_state = START;
                    next_token_valid = 1'b1;
                    update_token_reg = 1'b1;
                    token_type_reg = 2'b00; // start split
                end else if (complete_split_reg) begin
                    next_state = COMPLETE;
                    next_token_valid = 1'b1;
                    update_token_reg = 1'b1;
                    token_type_reg = 2'b01; // complete split
                end
            end
            
            START: begin
                next_state = WAIT;
                next_token_valid = 1'b0;
            end
            
            WAIT: begin
                if (complete_split_reg) begin
                    next_state = COMPLETE;
                    next_token_valid = 1'b1;
                    update_token_reg = 1'b1;
                    token_type_reg = 2'b01; // complete split
                end
            end
            
            COMPLETE: begin
                next_state = IDLE;
                next_token_valid = 1'b0;
            end
        endcase
    end

    // 命令字节生成逻辑 - 组合逻辑部分
    always @(*) begin
        if (update_token_reg) begin
            if (token_type_reg == 2'b00) // start split
                command_byte = {transaction_type_reg[1:0], 2'b00, port_num_reg};
            else // complete split
                command_byte = {transaction_type_reg[1:0], 2'b10, port_num_reg};
                
            // 令牌生成逻辑 - 组合逻辑部分
            next_split_token = {hub_addr_reg, command_byte, 4'b0000}; // CRC5 omitted
        end else begin
            command_byte = command_byte; // 保持原值
            next_split_token = split_token; // 保持原值
        end
    end

    // 状态和控制信号寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            token_valid <= 1'b0;
            split_token <= 16'h0000;
        end else begin
            state <= next_state;
            token_valid <= next_token_valid;
            split_token <= next_split_token;
        end
    end
    
endmodule