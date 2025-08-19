//SystemVerilog
module dma_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    // 控制接口
    input start_dma,
    input [AWIDTH-1:0] src_addr, dst_addr,
    input [15:0] length,
    output reg dma_busy, dma_done,
    // 内存接口
    output reg [AWIDTH-1:0] mem_addr,
    output reg [DWIDTH-1:0] mem_wdata,
    output reg mem_wr, mem_rd,
    input [DWIDTH-1:0] mem_rdata,
    input mem_ready
);
    // 定义状态常量 - 使用独热编码提高状态机可靠性
    localparam [4:0] IDLE  = 5'b00001;
    localparam [4:0] READ  = 5'b00010;
    localparam [4:0] WRITE = 5'b00100;
    localparam [4:0] NEXT  = 5'b01000;
    localparam [4:0] DONE  = 5'b10000;
    
    reg [4:0] state, next_state;
    reg [AWIDTH-1:0] current_src, current_dst;
    reg [15:0] remain;
    reg [DWIDTH-1:0] buffer;
    reg last_transfer;
    
    // 状态转移逻辑 - 优化比较链
    always @(*) begin
        next_state = state; // 默认保持当前状态
        last_transfer = (remain == 16'd1);
        
        case (1'b1) // 使用优先级编码器风格
            state[0]: begin // IDLE
                if (start_dma) next_state = READ;
            end
            state[1]: begin // READ
                if (mem_ready) next_state = WRITE;
            end
            state[2]: begin // WRITE
                if (mem_ready) next_state = NEXT;
            end
            state[3]: begin // NEXT
                next_state = last_transfer ? DONE : READ;
            end
            state[4]: begin // DONE
                if (!start_dma) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 寄存器更新逻辑 - 优化控制信号生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dma_busy <= 1'b0;
            dma_done <= 1'b0;
            mem_wr <= 1'b0;
            mem_rd <= 1'b0;
            current_src <= {AWIDTH{1'b0}};
            current_dst <= {AWIDTH{1'b0}};
            remain <= 16'd0;
            buffer <= {DWIDTH{1'b0}};
            mem_addr <= {AWIDTH{1'b0}};
            mem_wdata <= {DWIDTH{1'b0}};
        end else begin
            state <= next_state;
            
            // 使用优先级编码器风格优化控制逻辑
            case (1'b1)
                state[0]: begin // IDLE
                    if (start_dma) begin
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        remain <= length;
                        dma_busy <= 1'b1;
                        dma_done <= 1'b0;
                    end
                end
                state[1]: begin // READ
                    mem_addr <= current_src;
                    mem_rd <= 1'b1;
                    
                    if (mem_ready) begin
                        buffer <= mem_rdata;
                        mem_rd <= 1'b0;
                    end
                end
                state[2]: begin // WRITE
                    mem_addr <= current_dst;
                    mem_wdata <= buffer;
                    mem_wr <= 1'b1;
                    
                    if (mem_ready) begin
                        mem_wr <= 1'b0;
                    end
                end
                state[3]: begin // NEXT
                    current_src <= current_src + (DWIDTH/8);
                    current_dst <= current_dst + (DWIDTH/8);
                    remain <= remain - 16'd1;
                end
                state[4]: begin // DONE
                    dma_busy <= 1'b0;
                    dma_done <= 1'b1;
                    
                    if (!start_dma) begin
                        dma_done <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule