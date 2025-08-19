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
    // 内存存储
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    
    // 指针寄存器及其流水线寄存器
    reg [$clog2(DEPTH):0] wr_ptr_stage1, rd_ptr_stage1;
    reg [$clog2(DEPTH):0] wr_ptr_stage2, rd_ptr_stage2;
    
    // 状态信号
    wire empty_stage1 = (wr_ptr_stage1 == rd_ptr_stage1);
    wire full_stage1 = (wr_ptr_stage1[$clog2(DEPTH)-1:0] == rd_ptr_stage1[$clog2(DEPTH)-1:0]) && 
                        (wr_ptr_stage1[$clog2(DEPTH)] != rd_ptr_stage1[$clog2(DEPTH)]);
    
    reg empty_stage2, full_stage2;
    
    // 写控制信号
    wire write_enable_stage1 = src_valid && !full_stage1;
    reg write_enable_stage2;
    reg [WIDTH-1:0] src_data_stage2;
    
    // 读控制信号
    wire read_enable_stage1 = !empty_stage1 && (!dst_valid || dst_ready);
    reg read_enable_stage2;

    // 状态寄存器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= 0;
            rd_ptr_stage2 <= 0;
            empty_stage2 <= 1;
            full_stage2 <= 0;
            write_enable_stage2 <= 0;
            read_enable_stage2 <= 0;
            src_data_stage2 <= 0;
        end else begin
            // 从第一级向第二级传递状态
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
            empty_stage2 <= empty_stage1;
            full_stage2 <= full_stage1;
            write_enable_stage2 <= write_enable_stage1;
            read_enable_stage2 <= read_enable_stage1;
            src_data_stage2 <= src_data;
        end
    end

    // FIFO 写操作
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
        end else begin
            // 写入操作
            if (write_enable_stage2) begin
                fifo[wr_ptr_stage2[$clog2(DEPTH)-1:0]] <= src_data_stage2;
                wr_ptr_stage1 <= wr_ptr_stage2 + 1;
            end else begin
                wr_ptr_stage1 <= wr_ptr_stage2;
            end
        end
    end

    // FIFO 读操作
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr_stage1 <= 0;
            dst_valid <= 0;
        end else begin
            // 读取操作
            if (read_enable_stage2) begin
                dst_data <= fifo[rd_ptr_stage2[$clog2(DEPTH)-1:0]];
                rd_ptr_stage1 <= rd_ptr_stage2 + 1;
                dst_valid <= 1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 0;
                rd_ptr_stage1 <= rd_ptr_stage2;
            end else begin
                rd_ptr_stage1 <= rd_ptr_stage2;
            end
        end
    end
    
    // 反压信号
    assign src_ready = !full_stage1;
endmodule