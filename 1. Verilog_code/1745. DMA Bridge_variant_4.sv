//SystemVerilog
module dma_bridge #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    
    // 控制接口
    input wire start_dma,
    input wire [AWIDTH-1:0] src_addr,
    input wire [AWIDTH-1:0] dst_addr,
    input wire [15:0] length,
    output reg dma_busy,
    output reg dma_done,
    
    // 内存接口
    output reg [AWIDTH-1:0] mem_addr,
    output reg [DWIDTH-1:0] mem_wdata,
    output reg mem_wr,
    output reg mem_rd,
    input wire [DWIDTH-1:0] mem_rdata,
    input wire mem_ready
);

    // 状态定义 - 使用独热编码改善时序
    localparam STATE_IDLE  = 5'b00001;
    localparam STATE_READ  = 5'b00010;
    localparam STATE_WAIT_READ = 5'b00100;
    localparam STATE_WRITE = 5'b01000;
    localparam STATE_DONE  = 5'b10000;
    
    // 控制状态寄存器
    reg [4:0] current_state;
    reg [4:0] next_state;
    
    // 数据流水线寄存器
    reg [AWIDTH-1:0] src_addr_reg;
    reg [AWIDTH-1:0] dst_addr_reg;
    reg [15:0] transfer_length;
    reg [15:0] transfers_remaining;
    
    // 数据缓冲寄存器
    reg [DWIDTH-1:0] data_buffer;
    reg buffer_valid;
    
    // 地址计算常量
    localparam BYTES_PER_TRANSFER = (DWIDTH/8);
    
    // 地址生成器
    reg [AWIDTH-1:0] read_addr;
    reg [AWIDTH-1:0] write_addr;
    
    // 状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 次态逻辑
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            STATE_IDLE: begin
                if (start_dma)
                    next_state = STATE_READ;
            end
            
            STATE_READ: begin
                next_state = STATE_WAIT_READ;
            end
            
            STATE_WAIT_READ: begin
                if (mem_ready)
                    next_state = STATE_WRITE;
            end
            
            STATE_WRITE: begin
                if (mem_ready) begin
                    if (transfers_remaining == 1)
                        next_state = STATE_DONE;
                    else
                        next_state = STATE_READ;
                end
            end
            
            STATE_DONE: begin
                if (!start_dma)
                    next_state = STATE_IDLE;
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end
    
    // 数据路径控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有控制和数据寄存器
            dma_busy <= 1'b0;
            dma_done <= 1'b0;
            mem_rd <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= {AWIDTH{1'b0}};
            mem_wdata <= {DWIDTH{1'b0}};
            src_addr_reg <= {AWIDTH{1'b0}};
            dst_addr_reg <= {AWIDTH{1'b0}};
            transfer_length <= 16'd0;
            transfers_remaining <= 16'd0;
            read_addr <= {AWIDTH{1'b0}};
            write_addr <= {AWIDTH{1'b0}};
            data_buffer <= {DWIDTH{1'b0}};
            buffer_valid <= 1'b0;
        end else begin
            // 默认信号值
            mem_rd <= 1'b0;
            mem_wr <= 1'b0;
            
            case (current_state)
                STATE_IDLE: begin
                    dma_done <= 1'b0;
                    buffer_valid <= 1'b0;
                    
                    if (start_dma) begin
                        // 寄存传输参数
                        src_addr_reg <= src_addr;
                        dst_addr_reg <= dst_addr;
                        transfer_length <= length;
                        transfers_remaining <= length;
                        
                        // 初始化地址寄存器
                        read_addr <= src_addr;
                        write_addr <= dst_addr;
                        
                        // 设置控制信号
                        dma_busy <= 1'b1;
                    end
                end
                
                STATE_READ: begin
                    // 发起读请求
                    mem_addr <= read_addr;
                    mem_rd <= 1'b1;
                end
                
                STATE_WAIT_READ: begin
                    if (mem_ready) begin
                        // 捕获数据到缓冲区
                        data_buffer <= mem_rdata;
                        buffer_valid <= 1'b1;
                    end else begin
                        mem_rd <= 1'b1;  // 保持读信号直到mem_ready
                    end
                end
                
                STATE_WRITE: begin
                    if (buffer_valid) begin
                        // 发起写请求
                        mem_addr <= write_addr;
                        mem_wdata <= data_buffer;
                        mem_wr <= 1'b1;
                        
                        if (mem_ready) begin
                            // 更新地址计数器
                            read_addr <= read_addr + BYTES_PER_TRANSFER;
                            write_addr <= write_addr + BYTES_PER_TRANSFER;
                            
                            // 更新剩余传输计数
                            transfers_remaining <= transfers_remaining - 1'b1;
                            
                            // 清除缓冲区有效标志
                            buffer_valid <= 1'b0;
                        end
                    end
                end
                
                STATE_DONE: begin
                    dma_busy <= 1'b0;
                    dma_done <= 1'b1;
                end
            endcase
        end
    end

endmodule