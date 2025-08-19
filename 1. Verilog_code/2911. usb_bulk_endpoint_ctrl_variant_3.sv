//SystemVerilog
module usb_bulk_endpoint_ctrl #(
    parameter MAX_PACKET_SIZE = 64,
    parameter BUFFER_DEPTH = 8
)(
    input wire clk_i, rst_n_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    input wire token_received_i,
    input wire [3:0] endpoint_i,
    output reg [7:0] data_o,
    output reg data_valid_o,
    output reg buffer_full_o,
    output reg buffer_empty_o,
    output reg [1:0] response_o
);
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // 流水线阶段寄存器
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg [$clog2(BUFFER_DEPTH)-1:0] write_ptr_stage1, write_ptr_stage2, write_ptr_stage3;
    reg [$clog2(BUFFER_DEPTH)-1:0] read_ptr_stage1, read_ptr_stage2, read_ptr_stage3;
    reg [$clog2(BUFFER_DEPTH):0] count_stage1, count_stage2, count_stage3;
    
    // 数据流水线寄存器
    reg [7:0] data_stage1, data_stage2;
    reg data_valid_stage1, data_valid_stage2;
    reg token_received_stage1, token_received_stage2;
    reg [3:0] endpoint_stage1, endpoint_stage2;
    
    // 控制信号流水线寄存器
    reg buffer_full_stage1, buffer_full_stage2;
    reg buffer_empty_stage1, buffer_empty_stage2;
    reg [1:0] next_state_stage1, next_state_stage2;
    
    // 缓冲存储器
    reg [7:0] buffer [0:BUFFER_DEPTH-1];
    
    // 流水线第一级：输入寄存
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            data_stage1 <= 8'h0;
            data_valid_stage1 <= 1'b0;
            token_received_stage1 <= 1'b0;
            endpoint_stage1 <= 4'h0;
        end else begin
            data_stage1 <= data_i;
            data_valid_stage1 <= data_valid_i;
            token_received_stage1 <= token_received_i;
            endpoint_stage1 <= endpoint_i;
        end
    end
    
    // 流水线第二级：状态更新和地址计算
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage1 <= IDLE;
            write_ptr_stage1 <= 0;
            read_ptr_stage1 <= 0;
            count_stage1 <= 0;
            next_state_stage1 <= IDLE;
            buffer_full_stage1 <= 1'b0;
            buffer_empty_stage1 <= 1'b1;
            
            data_stage2 <= 8'h0;
            data_valid_stage2 <= 1'b0;
            token_received_stage2 <= 1'b0;
            endpoint_stage2 <= 4'h0;
        end else begin
            // 传递数据到下一级
            data_stage2 <= data_stage1;
            data_valid_stage2 <= data_valid_stage1;
            token_received_stage2 <= token_received_stage1;
            endpoint_stage2 <= endpoint_stage1;
            
            // 状态更新
            state_stage1 <= next_state_stage1;
            
            // 流水线控制逻辑
            if (data_valid_stage1 && !buffer_full_stage1 && state_stage1 == RX) begin
                write_ptr_stage1 <= (write_ptr_stage1 == BUFFER_DEPTH-1) ? 0 : write_ptr_stage1 + 1;
                count_stage1 <= count_stage1 + 1;
            end
            
            // 状态条件计算
            buffer_full_stage1 <= (count_stage1 == BUFFER_DEPTH-1 && data_valid_stage1 && state_stage1 == RX) || 
                               (count_stage1 == BUFFER_DEPTH);
            buffer_empty_stage1 <= (count_stage1 == 1 && state_stage1 == TX) || 
                                (count_stage1 == 0);
                                
            // 下一状态逻辑抽离为独立流水线级
            case (state_stage1)
                IDLE: next_state_stage1 <= token_received_stage1 ? (endpoint_stage1[0] ? RX : TX) : IDLE;
                RX:   next_state_stage1 <= buffer_full_stage1 ? IDLE : RX;
                TX:   next_state_stage1 <= buffer_empty_stage1 ? IDLE : TX;
                STALL: next_state_stage1 <= IDLE;
                default: next_state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 流水线第三级：存储器访问和输出生成
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage2 <= IDLE;
            write_ptr_stage2 <= 0;
            read_ptr_stage2 <= 0;
            count_stage2 <= 0;
            buffer_full_stage2 <= 1'b0;
            buffer_empty_stage2 <= 1'b1;
            next_state_stage2 <= IDLE;
        end else begin
            // 传递状态到下一级
            state_stage2 <= state_stage1;
            write_ptr_stage2 <= write_ptr_stage1;
            read_ptr_stage2 <= read_ptr_stage1;
            count_stage2 <= count_stage1;
            buffer_full_stage2 <= buffer_full_stage1;
            buffer_empty_stage2 <= buffer_empty_stage1;
            next_state_stage2 <= next_state_stage1;
            
            // 存储器写入逻辑
            if (data_valid_stage2 && !buffer_full_stage2 && state_stage2 == RX) begin
                buffer[write_ptr_stage2] <= data_stage2;
            end
        end
    end
    
    // 流水线第四级：最终输出
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage3 <= IDLE;
            write_ptr_stage3 <= 0;
            read_ptr_stage3 <= 0;
            count_stage3 <= 0;
            
            data_o <= 8'h0;
            data_valid_o <= 1'b0;
            buffer_full_o <= 1'b0;
            buffer_empty_o <= 1'b1;
            response_o <= 2'b00;
        end else begin
            // 更新最终状态
            state_stage3 <= state_stage2;
            write_ptr_stage3 <= write_ptr_stage2;
            read_ptr_stage3 <= read_ptr_stage2;
            count_stage3 <= count_stage2;
            
            // 生成最终输出
            buffer_full_o <= buffer_full_stage2;
            buffer_empty_o <= buffer_empty_stage2;
            
            // 读取逻辑和输出生成
            if (state_stage3 == TX && !buffer_empty_o) begin
                data_o <= buffer[read_ptr_stage3];
                data_valid_o <= 1'b1;
                read_ptr_stage3 <= (read_ptr_stage3 == BUFFER_DEPTH-1) ? 0 : read_ptr_stage3 + 1;
            end else begin
                data_valid_o <= 1'b0;
            end
            
            // 响应生成
            response_o <= state_stage3;
        end
    end
    
endmodule