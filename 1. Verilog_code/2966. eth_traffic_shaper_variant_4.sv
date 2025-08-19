//SystemVerilog
module eth_traffic_shaper #(
    parameter RATE_MBPS = 1000,
    parameter BURST_BYTES = 16384
)(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input in_valid,
    output reg [7:0] data_out,
    output reg out_valid,
    output reg credit_overflow
);
    // IEEE 1364-2005标准
    
    localparam TOKEN_INC = RATE_MBPS * 1000 / 8;  // Bytes per us
    
    // 优化状态编码
    localparam IDLE = 2'b00;
    localparam CHECK_TOKEN = 2'b01;
    localparam SEND_DATA = 2'b10;
    
    reg [31:0] token_counter;
    reg [31:0] byte_counter;
    reg [1:0] shaper_state;
    
    // 将输入数据寄存化，前向重定时
    reg [7:0] data_in_reg;
    reg in_valid_reg;
    
    // 预计算下一个token计数值
    wire [31:0] next_token_count = token_counter + TOKEN_INC;
    wire token_limit_reached = next_token_count >= BURST_BYTES;
    
    // 微秒时间计数器检查
    wire us_tick = (byte_counter == 125000 - 1); // 1 us @ 125MHz，优化比较操作
    
    // 输入数据寄存器化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h0;
            in_valid_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            in_valid_reg <= in_valid;
        end
    end
    
    // 将token_counter计算前移，减少关键路径延迟
    reg [31:0] next_token_counter;
    reg token_overflow_pre;
    
    // 预计算token计数器的下一个值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_token_counter <= BURST_BYTES;
            token_overflow_pre <= 1'b1;
        end else begin
            if (us_tick) begin
                next_token_counter <= token_limit_reached ? BURST_BYTES : next_token_count;
            end else if (shaper_state == CHECK_TOKEN && |token_counter) begin
                next_token_counter <= token_counter - 1'b1;
            end else begin
                next_token_counter <= token_counter;
            end
            
            token_overflow_pre <= (next_token_counter == BURST_BYTES);
        end
    end
    
    // 主状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_counter <= BURST_BYTES;
            byte_counter <= 0;
            shaper_state <= IDLE;
            credit_overflow <= 0;
            out_valid <= 0;
            data_out <= 8'h0;
        end else begin
            // 更新时间计数器
            if (us_tick) begin
                byte_counter <= 0;
                token_counter <= next_token_counter;
            end else begin
                byte_counter <= byte_counter + 1'b1;
                token_counter <= next_token_counter;
            end
            
            // 默认值设置
            out_valid <= 1'b0;
            
            // 状态机优化
            case(shaper_state)
                IDLE: begin
                    // 使用寄存后的输入信号
                    if (in_valid_reg) shaper_state <= CHECK_TOKEN;
                end
                
                CHECK_TOKEN: begin
                    if (|token_counter) begin // 使用归约运算符检查非零
                        data_out <= data_in_reg;
                        out_valid <= 1'b1;
                        shaper_state <= SEND_DATA;
                    end
                end
                
                SEND_DATA: begin
                    shaper_state <= IDLE;
                end
                
                default: begin
                    shaper_state <= IDLE;
                end
            endcase
            
            // 使用预计算的溢出标志
            credit_overflow <= token_overflow_pre;
        end
    end
endmodule