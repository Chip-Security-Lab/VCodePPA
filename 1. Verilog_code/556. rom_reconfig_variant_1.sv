//SystemVerilog
module rom_reconfig #(parameter DW=8, AW=5)(
    input clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);
    // 这实际上是RAM而不是ROM
    reg [DW-1:0] storage [0:(1<<AW)-1];
    
    // 初始化为0值
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            storage[i] = {DW{1'b0}};
    end
    
    // 流水线寄存器
    reg [DW-1:0] wr_data_stage1;
    reg [AW-1:0] wr_addr_stage1;
    reg wr_en_stage1;
    reg [AW-1:0] rd_addr_stage1;
    reg [DW-1:0] rd_data_stage1;

    // 合并的流水线逻辑
    always @(posedge clk) begin
        // 流水线阶段1
        wr_data_stage1 <= wr_data;
        wr_addr_stage1 <= wr_addr;
        wr_en_stage1 <= wr_en;
        rd_addr_stage1 <= rd_addr;

        // 流水线阶段2
        if (wr_en_stage1) begin
            storage[wr_addr_stage1] <= wr_data_stage1;
        end
        rd_data_stage1 <= storage[rd_addr_stage1];
        
        // 输出阶段
        rd_data <= rd_data_stage1;
    end
endmodule