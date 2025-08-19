//SystemVerilog
// 顶层模块 - 将寄存器文件的功能分离为读写控制模块和存储模块
module async_reset_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,      // Active-low asynchronous reset
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output wire [DATA_WIDTH-1:0]  rdata
);
    // 内部连接信号
    wire [DATA_WIDTH-1:0] mem_rdata;
    wire mem_we;
    wire [ADDR_WIDTH-1:0] mem_waddr;
    wire [DATA_WIDTH-1:0] mem_wdata;
    
    // 实例化存储控制模块
    memory_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) mem_ctrl_inst (
        .clk(clk),
        .arst_n(arst_n),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .mem_we(mem_we),
        .mem_waddr(mem_waddr),
        .mem_wdata(mem_wdata)
    );
    
    // 实例化存储模块
    storage_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) storage_inst (
        .clk(clk),
        .arst_n(arst_n),
        .we(mem_we),
        .waddr(mem_waddr),
        .wdata(mem_wdata),
        .raddr(raddr),
        .rdata(rdata)
    );
    
endmodule

// 存储控制模块 - 负责写控制和优化
module memory_control #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output reg                    mem_we,
    output reg  [ADDR_WIDTH-1:0]  mem_waddr,
    output reg  [DATA_WIDTH-1:0]  mem_wdata
);
    // 写控制 - 可以在这里添加额外的写逻辑（地址检查、数据处理等）
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            mem_we <= 1'b0;
            mem_waddr <= {ADDR_WIDTH{1'b0}};
            mem_wdata <= {DATA_WIDTH{1'b0}};
        end
        else begin
            mem_we <= we;
            mem_waddr <= waddr;
            mem_wdata <= wdata;
        end
    end
endmodule

// 存储阵列模块 - 负责实际存储和读取操作
module storage_array #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output wire [DATA_WIDTH-1:0]  rdata
);
    // 寄存器阵列声明
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // 异步读
    assign rdata = mem[raddr];
    
    // 复位/写控制逻辑 - 使用 while 循环代替 for 循环
    generate
        reg [ADDR_WIDTH:0] cell_index;
        
        always @(posedge clk or negedge arst_n) begin
            if (!arst_n) begin
                // 初始化循环变量
                cell_index = 0;
                // While 循环进行复位
                while (cell_index < DEPTH) begin
                    mem[cell_index] <= {DATA_WIDTH{1'b0}};
                    cell_index = cell_index + 1;
                end
            end
            else if (we) begin
                mem[waddr] <= wdata;
            end
        end
    endgenerate
endmodule