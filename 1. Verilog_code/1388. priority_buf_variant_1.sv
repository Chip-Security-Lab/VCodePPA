//SystemVerilog
module priority_buf #(parameter DW=16) (
    input clk, rst_n,
    input [1:0] pri_level,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] mem[0:3];
    reg [DW-1:0] mem_rd_data;
    reg [1:0] rd_ptr = 0;
    
    // 并行前缀减法器实现 (4位)
    wire [3:0] a = {2'b00, rd_ptr};  // 扩展为4位
    wire [3:0] b = 4'b0001;          // 常数1
    wire [3:0] next_rd_ptr_full;     // 4位结果
    wire [1:0] next_rd_ptr;          // 最终2位结果
    
    // 生成位
    wire [3:0] g = a & (~b);
    
    // 传播位
    wire [3:0] p = a | (~b);
    
    // 并行前缀树（Kogge-Stone结构）- 第一级
    wire [3:0] g_level1, p_level1;
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    
    // 并行前缀树 - 第二级
    wire [3:0] g_level2, p_level2;
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    
    // 计算结果
    assign next_rd_ptr_full[0] = a[0] ^ b[0] ^ 1'b1; // 初始进位为1(减法)
    assign next_rd_ptr_full[1] = a[1] ^ b[1] ^ ~g_level2[0];
    assign next_rd_ptr_full[2] = a[2] ^ b[2] ^ ~g_level2[1];
    assign next_rd_ptr_full[3] = a[3] ^ b[3] ^ ~g_level2[2];
    
    // 取低2位作为最终结果，并处理环形缓冲区的循环逻辑
    assign next_rd_ptr = (rd_ptr == 2'b11) ? 2'b00 : next_rd_ptr_full[1:0];
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mem[0] <= 0; mem[1] <= 0;
            mem[2] <= 0; mem[3] <= 0;
        end
        else if(wr_en) 
            mem[pri_level] <= din;
    end
    
    // 重定时：将读取数据的寄存器放在组合逻辑之前
    always @(posedge clk) begin
        if(rd_en) begin
            mem_rd_data <= mem[rd_ptr];
            rd_ptr <= next_rd_ptr;
        end
    end
    
    // 输出寄存器移至后级
    always @(posedge clk) begin
        dout <= mem_rd_data;
    end
endmodule