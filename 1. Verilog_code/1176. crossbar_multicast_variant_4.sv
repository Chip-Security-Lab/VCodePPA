//SystemVerilog
//IEEE 1364-2005 Verilog
module crossbar_multicast #(
    parameter DW = 8,  // 数据宽度
    parameter N = 4    // 端口数量
)(
    input clk,
    input [N*DW-1:0] din,       // 打平的输入数组
    input [N*N-1:0] dest_mask,  // 打平的目标掩码
    output reg [N*DW-1:0] dout  // 打平的输出数组
);
    // 将输入和输出数据重新解释为二维数组便于访问
    wire [DW-1:0] din_2d [0:N-1];
    reg [DW-1:0] dout_2d [0:N-1];
    
    // 生成二维输入数组
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_din_map
            assign din_2d[g] = din[g*DW +: DW];
        end
    endgenerate
    
    integer i, j;
    
    // Brent-Kung加法器内部信号
    wire [DW-1:0] p_stage1, g_stage1;
    wire [DW-1:0] p_stage2, g_stage2;
    wire [DW-1:0] p_stage3, g_stage3;
    wire [DW-1:0] carry;
    wire [DW:0] sum;
    
    // 组合逻辑实现crossbar功能
    always @(*) begin
        // 初始化输出为0
        for (i = 0; i < N; i = i + 1) begin
            dout_2d[i] = {DW{1'b0}};
        end
        
        // 实现crossbar功能
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                if (dest_mask[i*N+j]) begin
                    // 使用Brent-Kung加法器处理数据
                    dout_2d[j] = brent_kung_add(din_2d[i], dout_2d[j]);
                end
            end
        end
        
        // 将二维输出映射回一维输出
        for (i = 0; i < N; i = i + 1) begin
            dout[i*DW +: DW] = dout_2d[i];
        end
    end
    
    // Brent-Kung加法器实现
    function [DW-1:0] brent_kung_add;
        input [DW-1:0] a, b;
        reg [DW-1:0] p, g;
        reg [DW:0] c;
        reg [DW-1:0] sum;
        integer k;
        begin
            // 阶段1: 生成初始的传播和生成信号
            for (k = 0; k < DW; k = k + 1) begin
                p[k] = a[k] ^ b[k];  // 传播信号
                g[k] = a[k] & b[k];  // 生成信号
            end
            
            // 阶段2: 第一级前缀计算
            c[0] = 1'b0; // 初始进位为0
            
            // 阶段3: 计算2位群组的传播和生成信号
            for (k = 0; k < DW-1; k = k + 2) begin
                g[k+1] = g[k+1] | (p[k+1] & g[k]);
                p[k+1] = p[k+1] & p[k];
            end
            
            // 阶段4: 计算4位群组的传播和生成信号
            for (k = 0; k < DW-3; k = k + 4) begin
                g[k+3] = g[k+3] | (p[k+3] & g[k+1]);
                p[k+3] = p[k+3] & p[k+1];
            end
            
            // 阶段5: 计算8位群组的传播和生成信号
            if (DW >= 8) begin
                for (k = 0; k < DW-7; k = k + 8) begin
                    g[k+7] = g[k+7] | (p[k+7] & g[k+3]);
                    p[k+7] = p[k+7] & p[k+3];
                end
            end
            
            // 阶段6: 反向传播进位
            c[1] = g[0];
            for (k = 1; k < DW; k = k + 1) begin
                if (k % 2 == 0) begin
                    c[k+1] = g[k];
                end else if (k % 4 == 1) begin
                    c[k+1] = g[k] | (p[k] & c[k]);
                end else if (k % 8 == 3) begin
                    c[k+1] = g[k] | (p[k] & c[k]);
                end else begin
                    c[k+1] = g[k] | (p[k] & c[k]);
                end
            end
            
            // 阶段7: 计算最终和
            for (k = 0; k < DW; k = k + 1) begin
                sum[k] = p[k] ^ c[k];
            end
            
            brent_kung_add = sum;
        end
    endfunction
    
endmodule