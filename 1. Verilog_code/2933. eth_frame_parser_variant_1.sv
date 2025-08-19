//SystemVerilog
// 顶层模块
module eth_frame_parser #(
    parameter BYTE_WIDTH = 8
) (
    input  wire                  clock,
    input  wire                  reset,
    input  wire                  data_valid,
    input  wire [BYTE_WIDTH-1:0] rx_byte,
    output reg  [47:0]           dest_addr,
    output reg  [47:0]           src_addr,
    output reg  [15:0]           eth_type,
    output reg                   frame_valid
);

    // 状态定义
    localparam S_IDLE     = 3'd0;
    localparam S_PREAMBLE = 3'd1;
    localparam S_SFD      = 3'd2;
    localparam S_DEST     = 3'd3;
    localparam S_SRC      = 3'd4;
    localparam S_TYPE     = 3'd5;
    localparam S_DATA     = 3'd6;
    
    reg [2:0] state;
    reg [3:0] byte_count;
    
    // 状态转换和处理信号
    wire preamble_detect;
    wire sfd_detect;
    wire invalid_preamble;
    wire dest_complete;
    wire src_complete;
    wire type_complete;
    
    // 使用子模块进行模式检测
    byte_pattern_detector #(
        .PATTERN_VALUE(8'h55)
    ) preamble_detector (
        .rx_byte(rx_byte),
        .match(preamble_detect)
    );
    
    byte_pattern_detector #(
        .PATTERN_VALUE(8'hD5)
    ) sfd_detector (
        .rx_byte(rx_byte),
        .match(sfd_detect)
    );
    
    // 使用子模块计算完成状态
    byte_counter_complete #(
        .TARGET_COUNT(4'd5)
    ) dest_counter (
        .byte_count(byte_count),
        .complete(dest_complete)
    );
    
    byte_counter_complete #(
        .TARGET_COUNT(4'd5)
    ) src_counter (
        .byte_count(byte_count),
        .complete(src_complete)
    );
    
    byte_counter_complete #(
        .TARGET_COUNT(4'd1)
    ) type_counter (
        .byte_count(byte_count),
        .complete(type_complete)
    );
    
    // 提取出的无效前导码检测逻辑
    assign invalid_preamble = !(preamble_detect || sfd_detect);
    
    // 状态迁移和数据处理逻辑
    always @(posedge clock) begin
        if (reset) begin
            state <= S_IDLE;
            byte_count <= 4'd0;
            frame_valid <= 1'b0;
            dest_addr <= 48'h0;
            src_addr <= 48'h0;
            eth_type <= 16'h0;
        end 
        else if (data_valid) begin
            case (state)
                S_IDLE: begin
                    if (preamble_detect) state <= S_PREAMBLE;
                end
                
                S_PREAMBLE: begin
                    if (sfd_detect) begin
                        state <= S_SFD;
                    end
                    else if (invalid_preamble) begin
                        state <= S_IDLE;
                    end
                end
                
                S_SFD: begin
                    state <= S_DEST;
                    byte_count <= 4'd0;
                end
                
                S_DEST: begin
                    dest_addr <= {dest_addr[39:0], rx_byte};
                    byte_count <= byte_count + 1'b1;
                    
                    if (dest_complete) begin
                        state <= S_SRC;
                        byte_count <= 4'd0;
                    end
                end
                
                S_SRC: begin
                    src_addr <= {src_addr[39:0], rx_byte};
                    byte_count <= byte_count + 1'b1;
                    
                    if (src_complete) begin
                        state <= S_TYPE;
                        byte_count <= 4'd0;
                    end
                end
                
                S_TYPE: begin
                    eth_type <= {eth_type[7:0], rx_byte};
                    byte_count <= byte_count + 1'b1;
                    
                    if (type_complete) begin
                        state <= S_DATA;
                        frame_valid <= 1'b1;
                    end
                end
                
                S_DATA: begin
                    frame_valid <= 1'b0;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule

// 字节模式检测器模块
module byte_pattern_detector #(
    parameter PATTERN_VALUE = 8'h00
) (
    input  wire [7:0] rx_byte,
    output wire       match
);
    assign match = (rx_byte == PATTERN_VALUE);
endmodule

// 字节计数完成检测器模块
module byte_counter_complete #(
    parameter TARGET_COUNT = 4'd0
) (
    input  wire [3:0] byte_count,
    output wire       complete
);
    assign complete = (byte_count == TARGET_COUNT);
endmodule