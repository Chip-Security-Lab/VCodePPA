//SystemVerilog
module eth_traffic_shaper #(
    parameter DATA_WIDTH = 8,
    parameter RATE_LIMIT = 100,  // Units: Mbps
    parameter TOKEN_MAX = 1500   // Maximum burst size in bytes
) (
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    input wire packet_start,
    input wire packet_end,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid_out,
    output reg tokens_available,
    output reg [15:0] token_count,
    input wire [15:0] packet_byte_limit, // Per-packet byte limit
    input wire enable_shaping
);
    localparam TOKEN_INC_PER_CYCLE = RATE_LIMIT / 8; // Bytes per cycle
    
    // 移除靠近输入的寄存器，改为直接使用输入信号
    // 内部状态寄存器
    reg [15:0] packet_byte_count;
    reg packet_in_progress;
    reg packet_throttled;
    
    // 预计算令牌填充逻辑
    wire [15:0] next_token_count;
    wire token_refill_needed = (token_count < TOKEN_MAX);
    wire [15:0] token_increment = (TOKEN_INC_PER_CYCLE > 0) ? TOKEN_INC_PER_CYCLE : 16'd0;
    wire [15:0] refilled_tokens = token_count + token_increment;
    wire token_overflow = (refilled_tokens < token_count) || (refilled_tokens > TOKEN_MAX);
    
    assign next_token_count = token_refill_needed ? 
                             (token_overflow ? TOKEN_MAX : refilled_tokens) : 
                             token_count;
    
    // 组合逻辑部分 - 计算下一个状态
    reg [DATA_WIDTH-1:0] next_data_out;
    reg next_data_valid_out;
    reg [15:0] next_token_count_final;
    reg next_tokens_available;
    reg [15:0] next_packet_byte_count;
    reg next_packet_in_progress;
    reg next_packet_throttled;
    
    always @(*) begin
        // 默认值保持当前状态
        next_data_out = data_out;
        next_data_valid_out = 1'b0; // 默认不输出数据
        next_token_count_final = next_token_count;
        next_tokens_available = (next_token_count > 0);
        next_packet_byte_count = packet_byte_count;
        next_packet_in_progress = packet_in_progress;
        next_packet_throttled = packet_throttled;
        
        // 包跟踪逻辑
        if (packet_start) begin
            next_packet_in_progress = 1'b1;
            next_packet_byte_count = 16'd0;
            next_packet_throttled = 1'b0;
        end else if (packet_end) begin
            next_packet_in_progress = 1'b0;
        end
        
        // 数据转发与流量整形
        if (data_valid_in && next_packet_in_progress && !next_packet_throttled) begin
            if (enable_shaping) begin
                // 检查令牌桶和包字节限制
                if (next_token_count > 0 && next_packet_byte_count < packet_byte_limit) begin
                    next_data_out = data_in;
                    next_data_valid_out = 1'b1;
                    next_token_count_final = next_token_count - 1'b1;
                    next_packet_byte_count = next_packet_byte_count + 1'b1;
                end else begin
                    next_data_valid_out = 1'b0;
                    next_packet_throttled = (next_packet_byte_count >= packet_byte_limit);
                end
            end else begin
                // 当禁用整形时的直通模式
                next_data_out = data_in;
                next_data_valid_out = data_valid_in;
                next_packet_byte_count = next_packet_byte_count + 1'b1;
            end
        end
    end
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            data_valid_out <= 1'b0;
            token_count <= TOKEN_MAX;
            tokens_available <= 1'b1;
            packet_byte_count <= 16'd0;
            packet_in_progress <= 1'b0;
            packet_throttled <= 1'b0;
        end else begin
            data_out <= next_data_out;
            data_valid_out <= next_data_valid_out;
            token_count <= next_token_count_final;
            tokens_available <= next_tokens_available;
            packet_byte_count <= next_packet_byte_count;
            packet_in_progress <= next_packet_in_progress;
            packet_throttled <= next_packet_throttled;
        end
    end
endmodule