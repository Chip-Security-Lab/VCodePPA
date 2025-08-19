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
    
    // 注册输入信号以实现前向寄存器重定时
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg data_valid_in_reg;
    reg packet_start_reg;
    reg packet_end_reg;
    reg [15:0] packet_byte_limit_reg;
    reg enable_shaping_reg;
    
    reg [15:0] packet_byte_count;
    reg packet_in_progress;
    reg packet_throttled;
    
    // 优化的组合逻辑信号
    wire token_refill_needed;
    wire [15:0] token_increment;
    wire can_forward_data;
    wire packet_limit_reached;
    
    // 输入寄存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
            data_valid_in_reg <= 1'b0;
            packet_start_reg <= 1'b0;
            packet_end_reg <= 1'b0;
            packet_byte_limit_reg <= 16'd0;
            enable_shaping_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            data_valid_in_reg <= data_valid_in;
            packet_start_reg <= packet_start;
            packet_end_reg <= packet_end;
            packet_byte_limit_reg <= packet_byte_limit;
            enable_shaping_reg <= enable_shaping;
        end
    end
    
    // 优化的令牌桶更新逻辑
    assign token_refill_needed = (token_count < TOKEN_MAX) && (TOKEN_INC_PER_CYCLE > 0);
    assign token_increment = (TOKEN_MAX - token_count < TOKEN_INC_PER_CYCLE) ? 
                            (TOKEN_MAX - token_count) : TOKEN_INC_PER_CYCLE;
    
    // 优化的数据转发决策逻辑
    assign packet_limit_reached = packet_byte_count >= packet_byte_limit_reg;
    
    // 通过提前计算条件减少比较链
    assign can_forward_data = data_valid_in_reg && 
                             packet_in_progress && 
                             !packet_throttled &&
                             (!enable_shaping_reg || 
                              (token_count > 0 && !packet_limit_reached));
    
    // 顺序逻辑
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
            // 令牌桶管理 - 优化的令牌更新
            if (token_refill_needed) begin
                token_count <= can_forward_data && enable_shaping_reg ? 
                              token_count + token_increment - 1'b1 :
                              token_count + token_increment;
            end else if (can_forward_data && enable_shaping_reg) begin
                token_count <= token_count - 1'b1;
            end
            
            // 令牌可用性状态
            tokens_available <= (token_count > 0) || (token_refill_needed && token_increment > 0);
            
            // 数据包状态跟踪 - 使用状态转换优化
            if (packet_start_reg) begin
                packet_in_progress <= 1'b1;
                packet_byte_count <= 16'd0;
                packet_throttled <= 1'b0;
            end else if (packet_end_reg) begin
                packet_in_progress <= 1'b0;
            end
            
            // 数据转发与字节计数 - 合并条件检查
            data_valid_out <= can_forward_data;
            
            if (can_forward_data) begin
                data_out <= data_in_reg;
                packet_byte_count <= packet_byte_count + 1'b1;
            end
            
            // 优化的节流状态更新
            if (data_valid_in_reg && packet_in_progress && !packet_throttled && 
                enable_shaping_reg && packet_limit_reached) begin
                packet_throttled <= 1'b1;
            end
        end
    end
endmodule