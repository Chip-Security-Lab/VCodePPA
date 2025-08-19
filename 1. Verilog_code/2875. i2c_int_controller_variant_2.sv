//SystemVerilog
module i2c_int_controller #(
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_sync,           // Synchronous reset
    inout sda,
    inout scl,
    // Interrupt interface
    output reg int_tx_empty,
    output reg int_rx_full,
    output reg int_error,
    // FIFO interface
    input  wr_en,
    input  [7:0] fifo_data_in,
    output [7:0] fifo_data_out
);
    // Unique feature: Interrupt system + dual-port FIFO
    reg [3:0] int_status;
    reg [7:0] fifo_mem[0:FIFO_DEPTH-1];
    reg [3:0] wr_ptr, rd_ptr;
    reg [7:0] fifo_out_reg;
    
    // 前向寄存器重定时-添加的中间寄存器
    reg wr_en_r;
    reg [7:0] fifo_data_in_r;
    reg [3:0] wr_ptr_next, rd_ptr_next;
    reg fifo_full, fifo_almost_empty;

    // State definitions for interrupt state machine
    parameter IDLE = 3'b000;
    parameter PROCESS_INT = 3'b001;
    parameter SERVICE_TX = 3'b010;
    parameter SERVICE_RX = 3'b011;
    reg [2:0] int_state, next_int_state;

    // FIFO data output
    assign fifo_data_out = fifo_out_reg;

    // 将输入信号寄存 - 减少输入到第一级寄存器的路径延迟
    always @(posedge clk) begin
        wr_en_r <= wr_en;
        fifo_data_in_r <= fifo_data_in;
    end
    
    // 跳跃进位加法器 - 计算wr_ptr_next和rd_ptr_next
    // 使用四级跳跃进位结构计算wr_ptr+1和rd_ptr+1
    wire [3:0] wr_p, rd_p;
    wire [3:0] wr_g, rd_g;
    wire [3:0] wr_c, rd_c;
    
    // 生成传播和生成位
    assign wr_p = wr_ptr ^ 4'b0001;  // 传播位 (P)
    assign wr_g = wr_ptr & 4'b0001;  // 生成位 (G)
    
    assign rd_p = rd_ptr ^ 4'b0001;  // 传播位 (P)
    assign rd_g = rd_ptr & 4'b0001;  // 生成位 (G)
    
    // 跳跃进位计算 - 第一级进位
    assign wr_c[0] = wr_g[0];
    assign wr_c[1] = wr_g[1] | (wr_p[1] & wr_c[0]);
    assign wr_c[2] = wr_g[2] | (wr_p[2] & wr_c[1]);
    assign wr_c[3] = wr_g[3] | (wr_p[3] & wr_c[2]);
    
    assign rd_c[0] = rd_g[0];
    assign rd_c[1] = rd_g[1] | (rd_p[1] & rd_c[0]);
    assign rd_c[2] = rd_g[2] | (rd_p[2] & rd_c[1]);
    assign rd_c[3] = rd_g[3] | (rd_p[3] & rd_c[2]);
    
    // 计算下一个指针值 (使用传播位和进位链)
    always @(*) begin
        // 使用跳跃进位加法器计算的结果
        wr_ptr_next = wr_p ^ {wr_c[2:0], 1'b0};
        rd_ptr_next = rd_p ^ {rd_c[2:0], 1'b0};
        
        // 进行模FIFO_DEPTH运算
        if (wr_ptr_next >= FIFO_DEPTH)
            wr_ptr_next = wr_ptr_next - FIFO_DEPTH;
            
        if (rd_ptr_next >= FIFO_DEPTH)
            rd_ptr_next = rd_ptr_next - FIFO_DEPTH;
            
        // FIFO状态计算
        fifo_full = (wr_ptr == rd_ptr);
        fifo_almost_empty = (wr_ptr == rd_ptr_next);
    end

    // Reset logic
    always @(posedge clk) begin
        if (rst_sync) begin
            int_tx_empty <= 1'b0;
            int_rx_full <= 1'b0;
            int_error <= 1'b0;
            int_status <= 4'h0;
            wr_ptr <= 4'h0;
            rd_ptr <= 4'h0;
            int_state <= IDLE;
            fifo_out_reg <= 8'h00;
        end
        else begin
            // 更新中断状态 - 已移动到此处
            int_tx_empty <= fifo_almost_empty;
            int_rx_full <= fifo_full;
            int_error <= (int_status != 0);
            
            // 状态机状态寄存 - 采用两阶段设计
            int_state <= next_int_state;
            
            // FIFO写操作 - 已经将条件判断移到组合逻辑
            if (wr_en_r && !fifo_full) begin
                fifo_mem[wr_ptr] <= fifo_data_in_r;
                wr_ptr <= wr_ptr_next;
            end
        end
    end

    // 中断状态机控制器 - 采用组合逻辑+寄存器方式
    always @(*) begin
        // 默认保持当前状态
        next_int_state = int_state;
        
        case (int_state)
            IDLE: begin
                if (int_status != 0)
                    next_int_state = PROCESS_INT;
            end
            
            PROCESS_INT: begin
                if (int_tx_empty)
                    next_int_state = SERVICE_TX;
                else if (int_rx_full)
                    next_int_state = SERVICE_RX;
                else
                    next_int_state = IDLE;
            end
            
            SERVICE_TX, SERVICE_RX: begin
                next_int_state = IDLE;
            end
            
            default: next_int_state = IDLE;
        endcase
    end
endmodule