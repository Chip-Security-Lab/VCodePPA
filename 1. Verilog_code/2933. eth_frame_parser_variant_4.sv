//SystemVerilog
//IEEE 1364-2005 Verilog标准
module eth_frame_parser #(parameter BYTE_WIDTH = 8) (
    input wire clock,
    input wire reset,
    input wire data_valid,
    input wire [BYTE_WIDTH-1:0] rx_byte,
    output reg [47:0] dest_addr,
    output reg [47:0] src_addr,
    output reg [15:0] eth_type,
    output reg frame_valid
);
    // 状态定义
    localparam S_IDLE = 3'd0, S_PREAMBLE = 3'd1, S_SFD = 3'd2;
    localparam S_DEST = 3'd3, S_SRC = 3'd4, S_TYPE = 3'd5, S_DATA = 3'd6;
    
    reg [2:0] state, next_state;
    reg [3:0] byte_count, next_byte_count;
    reg next_frame_valid;
    reg [47:0] next_dest_addr;
    reg [47:0] next_src_addr;
    reg [15:0] next_eth_type;
    
    // 状态转换逻辑
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        if (data_valid) begin
            case (state)
                S_IDLE: begin
                    if (rx_byte == 8'h55)
                        next_state = S_PREAMBLE;
                end
                
                S_PREAMBLE: begin
                    if (rx_byte == 8'hD5)
                        next_state = S_SFD;
                    else if (rx_byte != 8'h55)
                        next_state = S_IDLE;
                end
                
                S_SFD: begin
                    next_state = S_DEST;
                end
                
                S_DEST: begin
                    if (byte_count == 4'd5) 
                        next_state = S_SRC;
                end
                
                S_SRC: begin
                    if (byte_count == 4'd5)
                        next_state = S_TYPE;
                end
                
                S_TYPE: begin
                    if (byte_count == 4'd1)
                        next_state = S_DATA;
                end
                
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
    
    // 字节计数器控制逻辑
    always @(*) begin
        // 默认保持当前值
        next_byte_count = byte_count;
        
        if (data_valid) begin
            case (state)
                S_SFD: begin
                    next_byte_count = 4'd0;
                end
                
                S_DEST, S_SRC, S_TYPE: begin
                    next_byte_count = byte_count + 1'b1;
                    
                    if ((state == S_DEST || state == S_SRC) && byte_count == 4'd5)
                        next_byte_count = 4'd0;
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // 目的地址处理逻辑
    always @(*) begin
        next_dest_addr = dest_addr;
        
        if (data_valid && state == S_DEST) begin
            next_dest_addr = {dest_addr[39:0], rx_byte};
        end
    end
    
    // 源地址处理逻辑
    always @(*) begin
        next_src_addr = src_addr;
        
        if (data_valid && state == S_SRC) begin
            next_src_addr = {src_addr[39:0], rx_byte};
        end
    end
    
    // 以太网类型处理逻辑
    always @(*) begin
        next_eth_type = eth_type;
        
        if (data_valid && state == S_TYPE) begin
            next_eth_type = {eth_type[7:0], rx_byte};
        end
    end
    
    // 帧有效信号控制逻辑
    always @(*) begin
        next_frame_valid = frame_valid;
        
        if (data_valid) begin
            if (state == S_TYPE && byte_count == 4'd1) begin
                next_frame_valid = 1'b1;
            end else if (state == S_DATA) begin
                next_frame_valid = 1'b0;
            end
        end
    end
    
    // 寄存器更新逻辑
    always @(posedge clock) begin
        if (reset) begin
            state <= S_IDLE;
            byte_count <= 4'd0;
            frame_valid <= 1'b0;
            dest_addr <= 48'd0;
            src_addr <= 48'd0;
            eth_type <= 16'd0;
        end else begin
            state <= next_state;
            byte_count <= next_byte_count;
            frame_valid <= next_frame_valid;
            dest_addr <= next_dest_addr;
            src_addr <= next_src_addr;
            eth_type <= next_eth_type;
        end
    end
endmodule