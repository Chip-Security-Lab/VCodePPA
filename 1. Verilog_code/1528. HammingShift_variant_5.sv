//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module HammingShift #(parameter DATA_BITS=4) (
    input clk, sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
    // 多级缓冲架构，用于分散高扇出信号的负载
    reg [DATA_BITS-1:0] data_stage1;           // 第一级缓冲
    
    // 第二级缓冲分割 - 为高扇出信号增加专用缓冲
    reg [DATA_BITS-1:0] data_buf_p0_p2_group1; // p0,p2计算组1
    reg [DATA_BITS-1:0] data_buf_p0_p2_group2; // p0,p2计算组2
    reg [DATA_BITS-1:0] data_buf_p1_group1;    // p1计算组1
    reg [DATA_BITS-1:0] data_buf_p1_group2;    // p1计算组2
    
    // 编码输出分布式缓冲
    reg [DATA_BITS+2:0] encoded_buf1;          // 编码输出缓冲1
    reg [DATA_BITS+2:0] encoded_buf2;          // 编码输出缓冲2
    
    // 采用流水线缓冲策略
    always @(posedge clk) begin
        // 第一级缓冲 - 集中所有数据位
        data_stage1 <= encoded_buf2[DATA_BITS-1:0];
        
        // 第二级缓冲 - 分散负载到更多专用缓冲区
        data_buf_p0_p2_group1 <= data_stage1;
        data_buf_p0_p2_group2 <= data_stage1;
        data_buf_p1_group1 <= data_stage1;
        data_buf_p1_group2 <= data_stage1;
        
        // 分散encoded高扇出信号的负载
        encoded_buf1 <= encoded;
        encoded_buf2 <= encoded_buf1;
    end
    
    // 为校验位计算拆分逻辑，降低每个门的扇入数量
    wire p0_part1 = data_buf_p0_p2_group1[1] ^ data_buf_p0_p2_group1[2];
    wire p0_part2 = data_buf_p0_p2_group2[3];
    wire p0 = p0_part1 ^ p0_part2;
    
    wire p1_part1 = data_buf_p1_group1[0] ^ data_buf_p1_group1[2];
    wire p1_part2 = data_buf_p1_group2[3];
    wire p1 = p1_part1 ^ p1_part2;
    
    wire p2_part1 = data_buf_p0_p2_group1[0] ^ data_buf_p0_p2_group1[1];
    wire p2_part2 = data_buf_p0_p2_group2[3];
    wire p2 = p2_part1 ^ p2_part2;
    
    // 注册校验位，减少编码逻辑的输出负载
    reg p0_reg, p1_reg, p2_reg;
    
    // 添加中间注册级，减少关键路径延迟
    reg p0_reg_stage, p1_reg_stage, p2_reg_stage;
    
    always @(posedge clk) begin
        // 添加中间注册级，分散时序压力
        p0_reg_stage <= p0;
        p1_reg_stage <= p1;
        p2_reg_stage <= p2;
        
        // 最终注册校验位结果
        p0_reg <= p0_reg_stage;
        p1_reg <= p1_reg_stage;
        p2_reg <= p2_reg_stage;
        
        // 更新移位寄存器
        encoded <= {encoded_buf2[DATA_BITS+1:0], sin};
        
        // 使用注册后的校验位更新输出
        encoded[4] <= p0_reg;
        encoded[5] <= p1_reg;
        encoded[6] <= p2_reg;
    end
endmodule