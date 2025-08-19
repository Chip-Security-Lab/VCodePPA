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
    reg [2:0] state;
    reg [AWIDTH-1:0] current_src, current_dst;
    reg [15:0] remain;
    reg [DWIDTH-1:0] buffer;
    
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
            case (state)
                IDLE: begin
                    if (start_dma) begin
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        remain <= length;
                        dma_busy <= 1;
                        dma_done <= 0;
                        state <= READ;
                    end
                end
                READ: begin
                    mem_addr <= current_src;
                    mem_rd <= 1;
                    mem_wr <= 0;
                    if (mem_ready) begin
                        buffer <= mem_rdata;
                        mem_rd <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    mem_addr <= current_dst;
                    mem_wdata <= buffer;
                    mem_wr <= 1;
                    mem_rd <= 0;
                    if (mem_ready) begin
                        mem_wr <= 0;
                        state <= NEXT;
                    end
                end
                NEXT: begin
                    current_src <= current_src + (DWIDTH/8);
                    current_dst <= current_dst + (DWIDTH/8);
                    remain <= remain - 1;
                    if (remain == 1) begin
                        state <= DONE;
                    end else begin
                        state <= READ;
                    end
                end
                DONE: begin
                    dma_busy <= 0;
                    dma_done <= 1;
                    if (!start_dma) begin
                        dma_done <= 0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule