//SystemVerilog
// 顶层模块
module sparse_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,     // Full address width
    parameter IMPLEMENTED_REGS = 16  // Only some addresses are implemented
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Write port
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    
    // Read port
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output wire [DATA_WIDTH-1:0]  read_data,
    output wire                   addr_valid    // Indicates if the address is implemented
);
    // 内部信号
    wire [3:0] write_index;
    wire [3:0] read_index;
    wire write_addr_valid;
    
    // 实例化地址解码器模块 - 写地址
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .IMPLEMENTED_REGS(IMPLEMENTED_REGS)
    ) write_decoder (
        .addr(write_addr),
        .reg_index(write_index),
        .addr_valid(write_addr_valid)
    );
    
    // 实例化地址解码器模块 - 读地址
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .IMPLEMENTED_REGS(IMPLEMENTED_REGS)
    ) read_decoder (
        .addr(read_addr),
        .reg_index(read_index),
        .addr_valid(addr_valid)
    );
    
    // 实例化寄存器存储模块
    register_storage #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMPLEMENTED_REGS(IMPLEMENTED_REGS)
    ) reg_store (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en & write_addr_valid),
        .write_index(write_index),
        .write_data(write_data),
        .read_index(read_index),
        .read_valid(addr_valid),
        .read_data(read_data)
    );
    
endmodule

// 地址解码器模块 - 处理地址验证和索引转换
module addr_decoder #(
    parameter ADDR_WIDTH = 8,
    parameter IMPLEMENTED_REGS = 16
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [3:0]            reg_index,
    output wire                  addr_valid
);
    // 简化地址验证逻辑
    assign addr_valid = ((addr & 8'h0F) == 8'h00) && (addr < 16*IMPLEMENTED_REGS);
    
    // 地址到索引的转换
    always @(*) begin
        if (addr_valid) begin
            reg_index = addr[7:4]; // Upper 4 bits form the index
        end
        else begin
            reg_index = 4'hF; // Invalid index
        end
    end
endmodule

// 寄存器存储模块 - 处理实际存储和读写操作
module register_storage #(
    parameter DATA_WIDTH = 32,
    parameter IMPLEMENTED_REGS = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  write_en,
    input  wire [3:0]            write_index,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [3:0]            read_index,
    input  wire                  read_valid,
    output reg  [DATA_WIDTH-1:0] read_data
);
    // 寄存器数组
    reg [DATA_WIDTH-1:0] sparse_regs [0:IMPLEMENTED_REGS-1];
    
    // 读操作优化 - 使用组合逻辑
    always @(*) begin
        if (read_valid) begin
            read_data = sparse_regs[read_index];
        end
        else begin
            read_data = {DATA_WIDTH{1'b0}};  // Return zeros for invalid addresses
        end
    end
    
    // 写操作优化 - 去除不必要的条件检查
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 使用生成语句初始化寄存器，提高可合成性
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_en) begin
            // 地址验证已在上层完成
            sparse_regs[write_index] <= write_data;
        end
    end
endmodule