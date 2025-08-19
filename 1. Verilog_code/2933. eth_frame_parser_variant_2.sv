//SystemVerilog
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
    
    // 流水线信号声明
    wire [2:0] next_state;
    wire [3:0] next_byte_count;
    
    reg [2:0] state_stage1;
    reg [3:0] byte_count_stage1;
    reg state_valid_stage1;
    
    reg [2:0] state_stage2;
    reg [3:0] byte_count_stage2;
    reg [BYTE_WIDTH-1:0] rx_byte_stage2;
    reg data_valid_stage2;
    
    reg [2:0] state_stage3;
    reg [3:0] byte_count_stage3;
    reg [BYTE_WIDTH-1:0] rx_byte_stage3;
    reg data_valid_stage3;
    
    reg [47:0] dest_addr_stage4;
    reg [47:0] src_addr_stage4;
    reg [15:0] eth_type_stage4;
    reg frame_valid_stage4;
    
    // 状态转换逻辑模块实例化
    state_transition #(
        .BYTE_WIDTH(BYTE_WIDTH)
    ) state_logic (
        .current_state(state_stage1),
        .byte_count(byte_count_stage1),
        .data_valid(data_valid),
        .rx_byte(rx_byte),
        .next_state(next_state),
        .next_byte_count(next_byte_count)
    );
    
    // 阶段1: 状态计算和字节计数更新
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= S_IDLE;
            byte_count_stage1 <= 4'd0;
            state_valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= next_state;
            byte_count_stage1 <= next_byte_count;
            state_valid_stage1 <= data_valid;
        end
    end
    
    // 流水线寄存器模块实例
    pipeline_register #(
        .DATA_WIDTH(BYTE_WIDTH + 3 + 4 + 1)
    ) stage1_to_stage2 (
        .clock(clock),
        .reset(reset),
        .in_data({state_stage1, byte_count_stage1, rx_byte, state_valid_stage1}),
        .out_data({state_stage2, byte_count_stage2, rx_byte_stage2, data_valid_stage2})
    );
    
    pipeline_register #(
        .DATA_WIDTH(BYTE_WIDTH + 3 + 4 + 1)
    ) stage2_to_stage3 (
        .clock(clock),
        .reset(reset),
        .in_data({state_stage2, byte_count_stage2, rx_byte_stage2, data_valid_stage2}),
        .out_data({state_stage3, byte_count_stage3, rx_byte_stage3, data_valid_stage3})
    );
    
    // 阶段4: 地址和类型处理
    addr_type_processor #(
        .BYTE_WIDTH(BYTE_WIDTH)
    ) addr_processor (
        .clock(clock),
        .reset(reset),
        .data_valid(data_valid_stage3),
        .state(state_stage3),
        .byte_count(byte_count_stage3),
        .rx_byte(rx_byte_stage3),
        .dest_addr(dest_addr_stage4),
        .src_addr(src_addr_stage4),
        .eth_type(eth_type_stage4),
        .frame_valid(frame_valid_stage4)
    );
    
    // 最终输出寄存器
    always @(posedge clock) begin
        if (reset) begin
            dest_addr <= 48'd0;
            src_addr <= 48'd0;
            eth_type <= 16'd0;
            frame_valid <= 1'b0;
        end else begin
            dest_addr <= dest_addr_stage4;
            src_addr <= src_addr_stage4;
            eth_type <= eth_type_stage4;
            frame_valid <= frame_valid_stage4;
        end
    end
endmodule

// 状态转换逻辑模块
module state_transition #(
    parameter BYTE_WIDTH = 8
)(
    input wire [2:0] current_state,
    input wire [3:0] byte_count,
    input wire data_valid,
    input wire [BYTE_WIDTH-1:0] rx_byte,
    output reg [2:0] next_state,
    output reg [3:0] next_byte_count
);
    // 状态定义
    localparam S_IDLE = 3'd0, S_PREAMBLE = 3'd1, S_SFD = 3'd2;
    localparam S_DEST = 3'd3, S_SRC = 3'd4, S_TYPE = 3'd5, S_DATA = 3'd6;
    
    // 计算下一状态和字节计数
    always @(*) begin
        next_state = current_state;
        next_byte_count = byte_count;
        
        if (data_valid) begin
            case (current_state)
                S_IDLE: 
                    if (rx_byte == 8'h55) next_state = S_PREAMBLE;
                
                S_PREAMBLE: 
                    if (rx_byte == 8'h55) next_state = S_PREAMBLE;
                    else if (rx_byte == 8'hD5) next_state = S_SFD;
                    else next_state = S_IDLE;
                
                S_SFD: begin
                    next_state = S_DEST;
                    next_byte_count = 4'd0;
                end
                
                S_DEST: 
                    if (byte_count < 4'd5) next_byte_count = byte_count + 1;
                    else begin
                        next_state = S_SRC;
                        next_byte_count = 4'd0;
                    end
                
                S_SRC:
                    if (byte_count < 4'd5) next_byte_count = byte_count + 1;
                    else begin
                        next_state = S_TYPE;
                        next_byte_count = 4'd0;
                    end
                
                S_TYPE:
                    if (byte_count < 4'd1) next_byte_count = byte_count + 1;
                    else begin
                        next_state = S_DATA;
                        next_byte_count = byte_count + 1;
                    end
                
                default: next_state = S_IDLE;
            endcase
        end
    end
endmodule

// 通用流水线寄存器模块
module pipeline_register #(
    parameter DATA_WIDTH = 8
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] in_data,
    output reg [DATA_WIDTH-1:0] out_data
);
    always @(posedge clock) begin
        if (reset) begin
            out_data <= {DATA_WIDTH{1'b0}};
        end else begin
            out_data <= in_data;
        end
    end
endmodule

// 地址和类型处理模块
module addr_type_processor #(
    parameter BYTE_WIDTH = 8
)(
    input wire clock,
    input wire reset,
    input wire data_valid,
    input wire [2:0] state,
    input wire [3:0] byte_count,
    input wire [BYTE_WIDTH-1:0] rx_byte,
    output reg [47:0] dest_addr,
    output reg [47:0] src_addr,
    output reg [15:0] eth_type,
    output reg frame_valid
);
    // 状态定义
    localparam S_IDLE = 3'd0, S_PREAMBLE = 3'd1, S_SFD = 3'd2;
    localparam S_DEST = 3'd3, S_SRC = 3'd4, S_TYPE = 3'd5, S_DATA = 3'd6;
    
    always @(posedge clock) begin
        if (reset) begin
            dest_addr <= 48'd0;
            src_addr <= 48'd0;
            eth_type <= 16'd0;
            frame_valid <= 1'b0;
        end 
        else if (data_valid) begin
            case (state)
                S_DEST: begin
                    dest_addr <= {dest_addr[39:0], rx_byte};
                    frame_valid <= 1'b0;
                end
                
                S_SRC: begin
                    src_addr <= {src_addr[39:0], rx_byte};
                    frame_valid <= 1'b0;
                end
                
                S_TYPE: begin
                    eth_type <= {eth_type[7:0], rx_byte};
                    frame_valid <= (byte_count == 4'd1) ? 1'b1 : 1'b0;
                end
                
                default: begin
                    if (state != S_DATA) frame_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule