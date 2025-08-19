//SystemVerilog
module low_power_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,                  // 写使能
    input wire [ADDR_WIDTH-1:0] addr,  // 地址
    input wire [DATA_WIDTH-1:0] din,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout,  // 数据输出
    input wire low_power_mode        // 低功耗模式信号
);

    // 使用二维数组表示RAM，优化存储结构
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 内部信号，用于优化时序
    reg [DATA_WIDTH-1:0] next_dout;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg we_reg;
    reg low_power_reg;
    
    // 第一阶段：寄存器输入信号，减少关键路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 0;
            we_reg <= 0;
            low_power_reg <= 0;
        end else begin
            addr_reg <= addr;
            we_reg <= we;
            low_power_reg <= low_power_mode;
        end
    end
    
    // 第二阶段：组合逻辑计算下一状态
    always @(*) begin
        if (low_power_reg) begin
            next_dout = dout; // 低功耗模式下保持输出不变
        end else begin
            next_dout = ram[addr_reg]; // 正常模式下读取数据
        end
    end
    
    // 第三阶段：更新RAM和输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (!low_power_reg) begin
            if (we_reg) ram[addr_reg] <= din;  // 写数据
            dout <= next_dout;                 // 读取数据
        end
    end
endmodule