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
    parameter IDLE = 3'b000;
    parameter READ = 3'b001;
    parameter WRITE = 3'b010;
    parameter NEXT = 3'b011;
    parameter DONE = 3'b100;
    
    reg [2:0] state, next_state;
    reg [AWIDTH-1:0] current_src, current_dst;
    reg [15:0] remain;
    reg [DWIDTH-1:0] buffer;
    
    // 流水线寄存器
    reg [AWIDTH-1:0] next_src, next_dst;
    reg [15:0] next_remain;
    reg next_mem_wr, next_mem_rd;
    reg [AWIDTH-1:0] next_mem_addr;
    reg [DWIDTH-1:0] next_mem_wdata;
    reg next_dma_busy, next_dma_done;
    
    // 第一级流水：计算下一状态和地址逻辑
    always @(*) begin
        // 默认值保持不变
        next_state = state;
        next_src = current_src;
        next_dst = current_dst;
        next_remain = remain;
        next_dma_busy = dma_busy;
        next_dma_done = dma_done;
        next_mem_wr = 0;
        next_mem_rd = 0;
        next_mem_addr = mem_addr;
        next_mem_wdata = mem_wdata;
        
        case (state)
            IDLE: begin
                if (start_dma) begin
                    next_src = src_addr;
                    next_dst = dst_addr;
                    next_remain = length;
                    next_dma_busy = 1;
                    next_dma_done = 0;
                    next_state = READ;
                end
            end
            READ: begin
                next_mem_addr = current_src;
                next_mem_rd = 1;
                if (mem_ready) begin
                    next_mem_rd = 0;
                    next_state = WRITE;
                end
            end
            WRITE: begin
                next_mem_addr = current_dst;
                next_mem_wdata = buffer;
                next_mem_wr = 1;
                if (mem_ready) begin
                    next_mem_wr = 0;
                    next_state = NEXT;
                end
            end
            NEXT: begin
                next_src = current_src + (DWIDTH/8);
                next_dst = current_dst + (DWIDTH/8);
                next_remain = remain - 1;
                if (remain == 1) begin
                    next_state = DONE;
                end else begin
                    next_state = READ;
                end
            end
            DONE: begin
                next_dma_busy = 0;
                next_dma_done = 1;
                if (!start_dma) begin
                    next_dma_done = 0;
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 第二级流水：更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dma_busy <= 0;
            dma_done <= 0;
            mem_wr <= 0;
            mem_rd <= 0;
            current_src <= 0;
            current_dst <= 0;
            remain <= 0;
            buffer <= 0;
            mem_addr <= 0;
            mem_wdata <= 0;
        end else begin
            state <= next_state;
            current_src <= next_src;
            current_dst <= next_dst;
            remain <= next_remain;
            dma_busy <= next_dma_busy;
            dma_done <= next_dma_done;
            mem_wr <= next_mem_wr;
            mem_rd <= next_mem_rd;
            mem_addr <= next_mem_addr;
            mem_wdata <= next_mem_wdata;
            
            // 特殊处理：捕获读取的数据
            if (state == READ && mem_ready) begin
                buffer <= mem_rdata;
            end
        end
    end
endmodule