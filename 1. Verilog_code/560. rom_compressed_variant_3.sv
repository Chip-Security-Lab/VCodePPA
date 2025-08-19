//SystemVerilog
module rom_compressed #(
    parameter AW = 8
)(
    input wire clk,               // 添加时钟信号用于流水线寄存器
    input wire rst_n,             // 添加复位信号
    input wire [AW-1:0] addr,     // 地址输入
    input wire enable,            // 数据使能信号
    output reg [31:0] data        // 输出数据
);

    // 内部流水线寄存器
    reg [AW-1:0] addr_stage1;
    reg [AW-1:0] addr_stage2;
    reg [AW-1:0] addr_compl_stage1;  // 存储非地址值
    reg [AW-1:0] addr_xor_stage1;    // 存储异或结果

    // 组合逻辑的中间结果
    wire [AW-1:0] addr_compl = ~addr;
    wire [AW-1:0] addr_xor = addr ^ {AW{1'b1}};
    wire [AW-1:0] addr_or = addr | {4'b0000, {(AW-4){1'b1}}};

    // 流水线第一阶段 - 计算和寄存基本操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            addr_compl_stage1 <= {AW{1'b0}};
            addr_xor_stage1 <= {AW{1'b0}};
        end
        else if (enable) begin
            addr_stage1 <= addr;
            addr_compl_stage1 <= addr_compl;
            addr_xor_stage1 <= addr_xor;
        end
    end

    // 流水线第二阶段 - 合并数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {AW{1'b0}};
            data <= 32'h0;
        end
        else if (enable) begin
            addr_stage2 <= addr_stage1;
            data <= {addr_stage1, addr_compl_stage1, addr_xor_stage1, addr_or};
        end
    end

endmodule