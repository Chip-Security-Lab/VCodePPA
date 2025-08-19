//SystemVerilog
module fifo_bridge #(parameter WIDTH=32, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] src_data,
    input src_valid,
    output src_ready,
    output reg [WIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    // FIFO存储
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    
    // 流水线级别1 - 写入控制逻辑
    reg [$clog2(DEPTH):0] wr_ptr_stage1, rd_ptr_stage1;
    wire empty_stage1 = (wr_ptr_stage1 == rd_ptr_stage1);
    wire full_stage1 = (wr_ptr_stage1[$clog2(DEPTH)-1:0] == rd_ptr_stage1[$clog2(DEPTH)-1:0]) && 
                      (wr_ptr_stage1[$clog2(DEPTH)] != rd_ptr_stage1[$clog2(DEPTH)]);
    reg write_valid_stage1;
    reg [WIDTH-1:0] write_data_stage1;
    
    // 流水线级别2 - 读取控制逻辑
    reg [$clog2(DEPTH):0] wr_ptr_stage2, rd_ptr_stage2;
    wire empty_stage2 = (wr_ptr_stage2 == rd_ptr_stage2);
    reg read_valid_stage2;
    reg [WIDTH-1:0] read_data_stage2;
    
    // 流水线级别3 - 输出控制
    reg output_valid_stage3;
    reg [WIDTH-1:0] output_data_stage3;
    
    // 写入流水线阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
            rd_ptr_stage1 <= 0;
            write_valid_stage1 <= 0;
            write_data_stage1 <= 0;
        end else begin
            // 捕获写入请求
            write_valid_stage1 <= src_valid && !full_stage1;
            write_data_stage1 <= src_data;
            
            // 更新写指针
            if (src_valid && !full_stage1) begin
                wr_ptr_stage1 <= wr_ptr_stage1 + 1;
            end
            
            // 同步读指针（从读取阶段）
            rd_ptr_stage1 <= rd_ptr_stage2;
        end
    end
    
    // FIFO存储实际写入
    always @(posedge clk) begin
        if (write_valid_stage1) begin
            fifo[wr_ptr_stage1[$clog2(DEPTH)-1:0]] <= write_data_stage1;
        end
    end
    
    // 读取流水线阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= 0;
            rd_ptr_stage2 <= 0;
            read_valid_stage2 <= 0;
            read_data_stage2 <= 0;
        end else begin
            // 同步写指针（从写入阶段）
            wr_ptr_stage2 <= wr_ptr_stage1;
            
            // 执行FIFO读取
            if (!empty_stage2 && (!output_valid_stage3 || dst_ready)) begin
                read_data_stage2 <= fifo[rd_ptr_stage2[$clog2(DEPTH)-1:0]];
                rd_ptr_stage2 <= rd_ptr_stage2 + 1;
                read_valid_stage2 <= 1;
            end else begin
                read_valid_stage2 <= 0;
            end
        end
    end
    
    // 输出流水线阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            output_valid_stage3 <= 0;
            output_data_stage3 <= 0;
        end else begin
            if (read_valid_stage2) begin
                output_data_stage3 <= read_data_stage2;
                output_valid_stage3 <= 1;
            end else if (dst_ready) begin
                output_valid_stage3 <= 0;
            end
        end
    end
    
    // 最终输出映射
    always @(posedge clk) begin
        if (!rst_n) begin
            dst_valid <= 0;
            dst_data <= 0;
        end else begin
            dst_valid <= output_valid_stage3;
            dst_data <= output_data_stage3;
        end
    end
    
    // 控制信号
    assign src_ready = !full_stage1;
endmodule