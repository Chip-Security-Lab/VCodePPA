//SystemVerilog
module crossbar_multicast #(parameter DW=8, parameter N=4) (
    input  wire         clk,
    input  wire [N*DW-1:0] din,      // 打平的数组
    input  wire [N*N-1:0]  dest_mask, // 打平的每个bit对应输出端口
    output reg  [N*DW-1:0] dout      // 打平的数组
);

    genvar i, j;
    wire [DW-1:0] din_array [0:N-1];
    reg  [DW-1:0] dout_array [0:N-1];
    wire [N-1:0]  dest_mask_2d [0:N-1];

    // 将打平的输入拆分为数组形式以提高可读性和效率
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_input_unpack
            assign din_array[i] = din[(i*DW) +: DW];
        end
    endgenerate

    // 优化的二维掩码结构
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_mask_unpack
            for (j = 0; j < N; j = j + 1) begin : gen_mask_bit
                assign dest_mask_2d[i][j] = dest_mask[i*N+j];
            end
        end
    endgenerate

    // 优化的组合逻辑输出生成
    integer src_idx, dst_idx;
    always @(*) begin
        // 默认输出初始化 - 一次性初始化
        for (dst_idx = 0; dst_idx < N; dst_idx = dst_idx + 1) begin
            dout_array[dst_idx] = {DW{1'b0}};
        end
        
        // 优化的交叉开关逻辑 - 使用优先级编码
        for (dst_idx = 0; dst_idx < N; dst_idx = dst_idx + 1) begin
            for (src_idx = N-1; src_idx >= 0; src_idx = src_idx - 1) begin
                if (dest_mask_2d[src_idx][dst_idx]) begin
                    dout_array[dst_idx] = din_array[src_idx];
                end
            end
        end
    end

    // 输出数组打平
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_output_pack
            always @(*) begin
                dout[(i*DW) +: DW] = dout_array[i];
            end
        end
    endgenerate

endmodule