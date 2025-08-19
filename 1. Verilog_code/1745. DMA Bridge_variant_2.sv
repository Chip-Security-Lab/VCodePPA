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
    reg mem_ready_r;
    reg [AWIDTH-1:0] addr_incr_src_r, addr_incr_dst_r;
    reg [15:0] remain_decr_r;
    reg remain_is_one_r;
    
    // 组合逻辑预计算
    wire [AWIDTH-1:0] addr_incr_src = current_src + (DWIDTH/8);
    wire [AWIDTH-1:0] addr_incr_dst = current_dst + (DWIDTH/8);
    wire [15:0] remain_decr = remain - 1'b1;
    wire remain_is_one = (remain == 16'd1);
    
    // 寄存预计算结果以减少关键路径
    always @(posedge clk) begin
        if (state == WRITE && mem_ready) begin
            addr_incr_src_r <= addr_incr_src;
            addr_incr_dst_r <= addr_incr_dst;
            remain_decr_r <= remain_decr;
            remain_is_one_r <= remain_is_one;
        end
        mem_ready_r <= mem_ready;
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (start_dma) next_state = READ;
            
            READ: 
                if (mem_ready_r) next_state = WRITE;
            
            WRITE: 
                if (mem_ready_r) next_state = NEXT;
            
            NEXT: 
                if (remain_is_one_r) next_state = DONE;
                else next_state = READ;
            
            DONE: 
                if (!start_dma) next_state = IDLE;
            
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 状态寄存器和输出逻辑
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
            
            case (state)
                IDLE: begin
                    if (start_dma) begin
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        remain <= length;
                        dma_busy <= 1'b1;
                        dma_done <= 1'b0;
                    end
                end
                
                READ: begin
                    mem_addr <= current_src;
                    mem_rd <= 1'b1;
                    mem_wr <= 1'b0;
                    if (mem_ready_r) begin
                        buffer <= mem_rdata;
                        mem_rd <= 1'b0;
                    end
                end
                
                WRITE: begin
                    mem_addr <= current_dst;
                    mem_wdata <= buffer;
                    mem_wr <= 1'b1;
                    mem_rd <= 1'b0;
                    if (mem_ready_r) begin
                        mem_wr <= 1'b0;
                    end
                end
                
                NEXT: begin
                    current_src <= addr_incr_src_r;
                    current_dst <= addr_incr_dst_r;
                    remain <= remain_decr_r;
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