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
    // 定义状态常量
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        READ = 3'b001,
        WRITE = 3'b010,
        NEXT = 3'b011,
        DONE = 3'b100
    } state_t;
    
    state_t state, next_state;
    reg [AWIDTH-1:0] current_src, current_dst;
    reg [15:0] remain;
    reg [DWIDTH-1:0] buffer;
    
    // 状态寄存器更新逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always_comb begin
        next_state = state; // 默认保持当前状态
        
        case (state)
            IDLE: begin
                if (start_dma) next_state = READ;
            end
            READ: begin
                if (mem_ready) next_state = WRITE;
            end
            WRITE: begin
                if (mem_ready) next_state = NEXT;
            end
            NEXT: begin
                if (remain == 1) next_state = DONE;
                else next_state = READ;
            end
            DONE: begin
                if (!start_dma) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 数据寄存器更新逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_src <= '0;
            current_dst <= '0;
            remain <= '0;
            buffer <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_dma) begin
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        remain <= length;
                    end
                end
                READ: begin
                    if (mem_ready) begin
                        buffer <= mem_rdata;
                    end
                end
                NEXT: begin
                    current_src <= current_src + (DWIDTH/8);
                    current_dst <= current_dst + (DWIDTH/8);
                    remain <= remain - 1;
                end
            endcase
        end
    end
    
    // 内存控制信号逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_addr <= '0;
            mem_wdata <= '0;
            mem_rd <= 1'b0;
            mem_wr <= 1'b0;
        end else begin
            case (state)
                READ: begin
                    mem_addr <= current_src;
                    mem_rd <= 1'b1;
                    mem_wr <= 1'b0;
                    if (mem_ready) begin
                        mem_rd <= 1'b0;
                    end
                end
                WRITE: begin
                    mem_addr <= current_dst;
                    mem_wdata <= buffer;
                    mem_wr <= 1'b1;
                    mem_rd <= 1'b0;
                    if (mem_ready) begin
                        mem_wr <= 1'b0;
                    end
                end
                default: begin
                    mem_rd <= 1'b0;
                    mem_wr <= 1'b0;
                end
            endcase
        end
    end
    
    // 状态输出逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_busy <= 1'b0;
            dma_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_dma) begin
                        dma_busy <= 1'b1;
                        dma_done <= 1'b0;
                    end
                end
                DONE: begin
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