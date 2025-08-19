//SystemVerilog
module regfile_async #(
    parameter WORD_SIZE = 16,
    parameter ADDR_BITS = 4,
    parameter NUM_WORDS = 16
)(
    input wire clk,
    input wire write_en,
    input wire [ADDR_BITS-1:0] raddr,
    input wire [ADDR_BITS-1:0] waddr,
    input wire [WORD_SIZE-1:0] wdata,
    output wire [WORD_SIZE-1:0] rdata
);
    // 主存储器阵列
    reg [WORD_SIZE-1:0] storage [0:NUM_WORDS-1];
    
    // 读地址寄存器 - 提高读路径的时序裕量
    reg [ADDR_BITS-1:0] raddr_reg;
    
    // 写入控制路径
    reg write_en_reg;
    reg [ADDR_BITS-1:0] waddr_reg;
    reg [WORD_SIZE-1:0] wdata_reg;
    
    // 读取数据寄存器 - 减少关键路径
    reg [WORD_SIZE-1:0] rdata_reg;
    
    // 合并所有时钟触发的逻辑到一个always块
    always @(posedge clk) begin
        // 写入流水线 - 寄存写入控制信号
        write_en_reg <= write_en;
        waddr_reg <= waddr;
        wdata_reg <= wdata;
        
        // 存储器写入操作
        if (write_en_reg) 
            storage[waddr_reg] <= wdata_reg;
        
        // 读取流水线 - 第一级：寄存读地址
        raddr_reg <= raddr;
        
        // 读取流水线 - 第二级：从存储器获取数据
        rdata_reg <= storage[raddr_reg];
    end
    
    // 输出数据
    assign rdata = rdata_reg;
    
endmodule