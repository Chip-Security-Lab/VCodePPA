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
    localparam TOKEN_INC = RATE_MBPS * 1000 / 8;  // Bytes per us
    
    // 寄存器定义
    reg [31:0] token_counter;
    reg [31:0] byte_counter;
    
    // 独热编码状态定义
    localparam IDLE = 4'b0001;
    localparam CHECK_TOKEN = 4'b0010;
    localparam OUTPUT_DATA = 4'b0100;
    localparam DEFAULT = 4'b1000;
    
    reg [3:0] shaper_state;
    reg [7:0] data_in_reg;    // 新增输入数据寄存器
    reg in_valid_reg;         // 新增输入有效信号寄存器
    
    // 寄存输入信号，降低输入端负载，改善建立时间
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h0;
            in_valid_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            in_valid_reg <= in_valid;
        end
    end
    
    // 令牌桶逻辑
    reg token_update;
    reg [31:0] next_token_counter;
    
    always @(*) begin
        // 计算下一个时钟周期的令牌数量
        if (byte_counter >= 125000 - 1) begin
            if (token_counter + TOKEN_INC > BURST_BYTES) 
                next_token_counter = BURST_BYTES;
            else
                next_token_counter = token_counter + TOKEN_INC;
            token_update = 1'b1;
        end else begin
            next_token_counter = token_counter;
            token_update = 1'b0;
        end
    end
    
    // 整形器状态机和控制逻辑
    reg [3:0] next_state;
    reg next_out_valid;
    reg [7:0] next_data_out;
    reg consume_token;
    
    always @(*) begin
        next_state = shaper_state;
        next_out_valid = 1'b0;
        next_data_out = data_out;
        consume_token = 1'b0;
        
        case(shaper_state)
            IDLE: begin
                if (in_valid_reg) 
                    next_state = CHECK_TOKEN;
            end
            
            CHECK_TOKEN: begin
                if (token_counter > 0) begin
                    next_data_out = data_in_reg;
                    next_out_valid = 1'b1;
                    consume_token = 1'b1;
                    next_state = OUTPUT_DATA;
                end
            end
            
            OUTPUT_DATA: begin
                next_out_valid = 1'b0;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 寄存器更新，移至组合逻辑后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_counter <= BURST_BYTES;
            byte_counter <= 32'h0;
            shaper_state <= IDLE;  // 初始化为独热编码的IDLE状态
            credit_overflow <= 1'b0;
            data_out <= 8'h0;
            out_valid <= 1'b0;
        end else begin
            // 更新令牌计数器
            if (token_update) begin
                token_counter <= consume_token ? next_token_counter - 1 : next_token_counter;
                byte_counter <= 32'h0;
            end else begin
                token_counter <= consume_token ? token_counter - 1 : token_counter;
                byte_counter <= byte_counter + 1;
            end
            
            // 更新状态和输出
            shaper_state <= next_state;
            data_out <= next_data_out;
            out_valid <= next_out_valid;
            
            // 更新溢出指示
            credit_overflow <= (next_token_counter == BURST_BYTES);
        end
    end
endmodule