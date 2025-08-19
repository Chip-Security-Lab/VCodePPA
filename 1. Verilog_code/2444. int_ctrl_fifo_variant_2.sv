//SystemVerilog
module int_ctrl_fifo #(parameter DEPTH=4, parameter DW=8) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DW-1:0] int_data,
    output wire full,
    output wire empty,
    output reg [DW-1:0] int_out,
    output wire valid_out
);

    // 流水线寄存器
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0] count;
    reg [$clog2(DEPTH)-1:0] wr_ptr_stage1, wr_ptr_stage2;
    reg [$clog2(DEPTH)-1:0] rd_ptr_stage1, rd_ptr_stage2;
    
    // 流水线控制信号
    reg wr_valid_stage1, wr_valid_stage2;
    reg rd_valid_stage1, rd_valid_stage2;
    reg [DW-1:0] int_data_stage1, int_data_stage2;
    reg [DW-1:0] read_data_stage1, read_data_stage2;
    
    // 状态信号
    wire wr_ready = !full;
    wire rd_ready = !empty;
    
    // 第一级流水线 - 写控制信号捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_valid_stage1 <= 1'b0;
            int_data_stage1 <= {DW{1'b0}};
        end else begin
            wr_valid_stage1 <= wr_en && wr_ready;
            int_data_stage1 <= int_data;
        end
    end
    
    // 第一级流水线 - 读控制信号捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid_stage1 <= 1'b0;
        end else begin
            rd_valid_stage1 <= rd_en && rd_ready;
        end
    end
    
    // 第一级流水线 - 写指针更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= {$clog2(DEPTH){1'b0}};
        end else begin
            wr_ptr_stage1 <= wr_ptr_stage2;
            if (wr_valid_stage1)
                wr_ptr_stage1 <= (wr_ptr_stage2 == DEPTH-1) ? 0 : wr_ptr_stage2 + 1;
        end
    end
    
    // 第一级流水线 - 读指针更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_stage1 <= {$clog2(DEPTH){1'b0}};
        end else begin
            rd_ptr_stage1 <= rd_ptr_stage2;
            if (rd_valid_stage1)
                rd_ptr_stage1 <= (rd_ptr_stage2 == DEPTH-1) ? 0 : rd_ptr_stage2 + 1;
        end
    end
    
    // 第二级流水线 - 控制信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_valid_stage2 <= 1'b0;
            rd_valid_stage2 <= 1'b0;
            int_data_stage2 <= {DW{1'b0}};
        end else begin
            wr_valid_stage2 <= wr_valid_stage1;
            rd_valid_stage2 <= rd_valid_stage1;
            int_data_stage2 <= int_data_stage1;
        end
    end
    
    // 第二级流水线 - 指针传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= {$clog2(DEPTH){1'b0}};
            rd_ptr_stage2 <= {$clog2(DEPTH){1'b0}};
        end else begin
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
        end
    end
    
    // FIFO存储操作 - 写入逻辑
    always @(posedge clk) begin
        if (wr_valid_stage1) begin
            fifo[wr_ptr_stage1] <= int_data_stage1;
        end
    end
    
    // FIFO存储操作 - 读取逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage1 <= {DW{1'b0}};
        end else begin
            if (rd_valid_stage1) begin
                read_data_stage1 <= fifo[rd_ptr_stage1];
                
                // 前递机制：处理读写同一地址的特殊情况
                if (wr_valid_stage1 && (wr_ptr_stage1 == rd_ptr_stage1))
                    read_data_stage1 <= int_data_stage1;
            end
        end
    end
    
    // 计数器逻辑 - 跟踪FIFO中的数据量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            if (wr_valid_stage1 && !rd_valid_stage1)
                count <= count + 1;
            else if (!wr_valid_stage1 && rd_valid_stage1)
                count <= count - 1;
            // 当同时读写时，count保持不变
        end
    end
    
    // 第三级流水线 - 读取数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage2 <= {DW{1'b0}};
        end else begin
            read_data_stage2 <= read_data_stage1;
        end
    end
    
    // 第三级流水线 - 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {DW{1'b0}};
        end else if (rd_valid_stage2) begin
            int_out <= read_data_stage2;
        end
    end
    
    // 状态信号生成
    assign full = (count >= DEPTH-1);
    assign empty = (count == 0);
    assign valid_out = rd_valid_stage2;
    
endmodule