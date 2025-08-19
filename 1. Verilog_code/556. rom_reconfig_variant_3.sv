//SystemVerilog
module rom_reconfig #(parameter DW=8, AW=5)(
    input wire clk,
    input wire wr_en,
    input wire [AW-1:0] wr_addr,
    input wire [DW-1:0] wr_data,
    input wire [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);
    // 存储器定义
    (* ram_style = "block" *) reg [DW-1:0] storage [0:(1<<AW)-1];
    
    // 初始化为0值
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            storage[i] = {DW{1'b0}};
    end
    
    // 增加流水线深度的优化读取逻辑
    reg [AW-1:0] rd_addr_stage1, rd_addr_stage2;
    reg [DW-1:0] rd_data_stage3, rd_data_stage4;
    reg read_valid_stage1, read_valid_stage2, read_valid_stage3, read_valid_stage4;
    reg wr_conflict_stage1, wr_conflict_stage2, wr_conflict_stage3;
    reg [DW-1:0] wr_data_stage1, wr_data_stage2, wr_data_stage3;
    reg [AW-1:0] wr_addr_stage1;
    reg [DW-1:0] storage_data_stage3;
    
    always @(posedge clk) begin
        // 第一级：地址寄存和初始冲突检测
        rd_addr_stage1 <= rd_addr;
        wr_conflict_stage1 <= wr_en && (wr_addr == rd_addr);
        wr_data_stage1 <= wr_data;
        wr_addr_stage1 <= wr_addr;
        read_valid_stage1 <= 1'b1;
        
        // 第二级：冲突检测进一步处理
        rd_addr_stage2 <= rd_addr_stage1;
        wr_conflict_stage2 <= wr_conflict_stage1;
        wr_data_stage2 <= wr_data_stage1;
        read_valid_stage2 <= read_valid_stage1;
        
        // 第三级：存储器读取
        storage_data_stage3 <= storage[rd_addr_stage2];
        wr_conflict_stage3 <= wr_conflict_stage2;
        wr_data_stage3 <= wr_data_stage2;
        read_valid_stage3 <= read_valid_stage2;
        
        // 第四级：数据选择逻辑
        if (wr_conflict_stage3)
            rd_data_stage4 <= wr_data_stage3;
        else
            rd_data_stage4 <= storage_data_stage3;
        read_valid_stage4 <= read_valid_stage3;
        
        // 第五级：最终输出寄存
        if (read_valid_stage4)
            rd_data <= rd_data_stage4;
            
        // 写入逻辑 - 保持不变
        if (wr_en) 
            storage[wr_addr] <= wr_data;
    end
endmodule