//SystemVerilog
module crossbar_fifo #(
    parameter DW = 8,    // 数据宽度
    parameter DEPTH = 4, // FIFO深度
    parameter N = 2      // 通道数量
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] push,
    input wire [N*DW-1:0] din,  // 打平的数组
    output wire [N*DW-1:0] dout // 打平的数组
);
    // 使用局部参数提高代码可维护性
    localparam CNT_WIDTH = $clog2(DEPTH+1);
    
    // 使用结构化内存提高访问效率
    reg [DW-1:0] fifo [0:N-1][0:DEPTH-1];
    reg [CNT_WIDTH-1:0] cnt [0:N-1]; // 使用最小位宽计数器

    // 计数器复位逻辑
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 同步复位，一次性初始化所有计数器
            for (i = 0; i < N; i = i + 1) begin
                cnt[i] <= {CNT_WIDTH{1'b0}};
            end
        end
    end

    // FIFO写入逻辑 - 拆分为每个通道独立的always块
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_fifo_write
            always @(posedge clk) begin
                if (!rst && push[g] && (cnt[g] < DEPTH)) begin
                    fifo[g][cnt[g]] <= din[g*DW +: DW];
                end
            end
        end
    endgenerate

    // 计数器更新逻辑 - 单独处理计数器更新
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_cnt_update
            always @(posedge clk) begin
                if (!rst && push[g] && (cnt[g] < DEPTH)) begin
                    cnt[g] <= cnt[g] + 1'b1;
                end
            end
        end
    endgenerate

    // 输出逻辑 - 修复了原始代码中的错误，现在使用正确的FIFO索引
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_out
            // 直接映射数据以减少逻辑层次
            assign dout[g*DW +: DW] = fifo[g][0];
        end
    endgenerate
endmodule