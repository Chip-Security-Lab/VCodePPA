//SystemVerilog
module crossbar_fifo #(
    parameter DW    = 8,    // 数据宽度
    parameter DEPTH = 4,    // FIFO深度
    parameter N     = 2     // 通道数量
)(
    input                  clk,    // 系统时钟
    input                  rst,    // 复位信号
    input      [N-1:0]     push,   // 写使能信号
    input      [N*DW-1:0]  din,    // 打平的输入数据
    output reg [N*DW-1:0]  dout    // 打平的输出数据
);

    // 内部信号定义 - 使用更清晰的结构
    reg [DW-1:0]  fifo_mem [0:N-1][0:DEPTH-1]; // 内存矩阵
    reg [4:0]     fifo_cnt [0:N-1];            // 每个FIFO的计数器
    reg [DW-1:0]  fifo_data_stage1 [0:N-1];    // 第一级流水线数据
    reg [DW-1:0]  fifo_data_stage2 [0:N-1];    // 第二级流水线数据
    
    // FIFO写入控制
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // 复位所有计数器
            for (i = 0; i < N; i = i + 1) begin
                fifo_cnt[i] <= 5'd0;
            end
        end else begin
            // 写入逻辑 - 为每个通道分别处理
            for (i = 0; i < N; i = i + 1) begin
                if (push[i] && fifo_cnt[i] < DEPTH) begin
                    // 提取相应通道的数据并写入FIFO
                    fifo_mem[i][fifo_cnt[i]] <= din[(i*DW) +: DW];
                    fifo_cnt[i] <= fifo_cnt[i] + 5'd1;
                end
            end
        end
    end
    
    // 数据流水线逻辑 - 将数据路径分割为两级
    // 第一级: 从内存中获取数据
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                fifo_data_stage1[i] <= {DW{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                // 从第一个FIFO中读取数据
                fifo_data_stage1[i] <= fifo_mem[0][0];
            end
        end
    end
    
    // 第二级: 数据处理并准备输出
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                fifo_data_stage2[i] <= {DW{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                fifo_data_stage2[i] <= fifo_data_stage1[i];
            end
        end
    end
    
    // 输出逻辑 - 将流水线数据映射到输出端口
    always @(posedge clk) begin
        if (rst) begin
            dout <= {(N*DW){1'b0}};
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                dout[(i*DW) +: DW] <= fifo_data_stage2[i];
            end
        end
    end

endmodule