//SystemVerilog
module rom_reconfig #(parameter DW=8, AW=5)(
    input clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data_stage1,
    output reg [DW-1:0] rd_data_stage2
);
    // 这实际上是RAM而不是ROM
    reg [DW-1:0] storage [0:(1<<AW)-1];
    
    // 初始化为0值
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            storage[i] = {DW{1'b0}};
    end
    
    // 写入逻辑
    always @(posedge clk) begin
        if(wr_en) 
            storage[wr_addr] <= wr_data;
    end
    
    // 读取逻辑使用先行借位减法器算法
    reg [DW-1:0] minuend;
    reg [DW-1:0] subtrahend;
    reg [DW-1:0] difference;
    reg borrow;

    always @(posedge clk) begin
        minuend <= storage[rd_addr]; // 获取被减数
        subtrahend <= storage[rd_addr + 1]; // 获取减数（示例，实际应根据需求调整）
        
        // 先行借位减法器实现
        {borrow, difference} = minuend - subtrahend; // 计算差值和借位
    end
    
    // 读取逻辑拆分为两个阶段
    always @(posedge clk) begin
        rd_data_stage1 <= difference; // 第一阶段读取
    end
    
    always @(posedge clk) begin
        rd_data_stage2 <= rd_data_stage1; // 第二阶段传递
    end
endmodule