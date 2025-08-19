//SystemVerilog
module range_decoder(
    input  wire [7:0] addr,
    output reg        rom_sel,
    output reg        ram_sel,
    output reg        io_sel,
    output reg        error
);
    // 定义地址范围常量提高可读性
    localparam ROM_MAX_ADDR = 8'h3F;  // ROM区域上限
    localparam RAM_MAX_ADDR = 8'hBF;  // RAM区域上限
    localparam IO_MAX_ADDR  = 8'hFE;  // IO区域上限
    
    // 定义地址范围编码
    localparam ROM_RANGE = 2'b00;
    localparam RAM_RANGE = 2'b01;
    localparam IO_RANGE  = 2'b10;
    localparam ERR_RANGE = 2'b11;
    
    // 第一阶段：地址范围检测
    reg [1:0] addr_range;
    
    // 地址范围检测逻辑
    always @(*) begin
        if (addr <= ROM_MAX_ADDR) begin
            addr_range = ROM_RANGE;
        end
        else if (addr <= RAM_MAX_ADDR) begin
            addr_range = RAM_RANGE;
        end
        else if (addr <= IO_MAX_ADDR) begin
            addr_range = IO_RANGE;
        end
        else begin
            addr_range = ERR_RANGE;
        end
    end
    
    // 第二阶段：生成选择信号
    always @(*) begin
        // 默认初始化所有输出信号
        rom_sel = 1'b0;
        ram_sel = 1'b0;
        io_sel  = 1'b0;
        error   = 1'b0;
        
        // 激活对应的选择信号
        case (addr_range)
            ROM_RANGE: rom_sel = 1'b1;
            RAM_RANGE: ram_sel = 1'b1;
            IO_RANGE:  io_sel  = 1'b1;
            ERR_RANGE: error   = 1'b1;
        endcase
    end
endmodule