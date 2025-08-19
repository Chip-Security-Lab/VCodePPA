//SystemVerilog
// 顶层模块 - 异步双端口RAM控制器
module async_ram_ctrl #(
    parameter DATA_W = 8,  // 数据宽度
    parameter ADDR_W = 4,  // 地址宽度
    parameter DEPTH = 16   // 存储深度
)(
    input wire wr_clk,             // 写时钟
    input wire rd_clk,             // 读时钟
    input wire rst,                // 异步复位
    input wire [DATA_W-1:0] din,   // 输入数据
    input wire [ADDR_W-1:0] waddr, // 写地址
    input wire [ADDR_W-1:0] raddr, // 读地址
    input wire we,                 // 写使能
    output wire [DATA_W-1:0] dout  // 输出数据
);

    // 存储器数据存储
    wire [DATA_W-1:0] mem_data [0:DEPTH-1];
    
    // 写入控制子模块实例化
    ram_write_ctrl #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .DEPTH(DEPTH)
    ) write_controller (
        .wr_clk(wr_clk),
        .rst(rst),
        .din(din),
        .waddr(waddr),
        .we(we),
        .mem_data(mem_data)
    );
    
    // 读取控制子模块实例化
    ram_read_ctrl #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .DEPTH(DEPTH)
    ) read_controller (
        .rd_clk(rd_clk),
        .raddr(raddr),
        .mem_data(mem_data),
        .dout(dout)
    );

endmodule

// 写控制器子模块
module ram_write_ctrl #(
    parameter DATA_W = 8,
    parameter ADDR_W = 4,
    parameter DEPTH = 16
)(
    input wire wr_clk,
    input wire rst,
    input wire [DATA_W-1:0] din,
    input wire [ADDR_W-1:0] waddr,
    input wire we,
    output reg [DATA_W-1:0] mem_data [0:DEPTH-1]
);
    
    integer i;
    // 流水线寄存器和控制信号
    reg [ADDR_W-1:0] waddr_stage1;
    reg [DATA_W-1:0] din_stage1;
    reg we_stage1;
    
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            // 复位流水线寄存器
            waddr_stage1 <= {ADDR_W{1'b0}};
            din_stage1 <= {DATA_W{1'b0}};
            we_stage1 <= 1'b0;
            
            // 复位所有存储单元
            for(i = 0; i < DEPTH; i = i + 1) begin
                mem_data[i] <= {DATA_W{1'b0}};
            end
        end else begin
            // 第一阶段流水线：寄存输入信号
            waddr_stage1 <= waddr;
            din_stage1 <= din;
            we_stage1 <= we;
            
            // 第二阶段流水线：写入数据到指定地址
            if (we_stage1) begin
                mem_data[waddr_stage1] <= din_stage1;
            end
        end
    end
    
endmodule

// 读控制器子模块
module ram_read_ctrl #(
    parameter DATA_W = 8,
    parameter ADDR_W = 4,
    parameter DEPTH = 16
)(
    input wire rd_clk,
    input wire [ADDR_W-1:0] raddr,
    input wire [DATA_W-1:0] mem_data [0:DEPTH-1],
    output reg [DATA_W-1:0] dout
);
    
    // 流水线寄存器
    reg [ADDR_W-1:0] raddr_stage1;
    reg [DATA_W-1:0] mem_data_read;
    
    always @(posedge rd_clk) begin
        // 第一阶段流水线：寄存地址
        raddr_stage1 <= raddr;
        
        // 第二阶段流水线：读取指定地址的数据
        mem_data_read <= mem_data[raddr_stage1];
        
        // 第三阶段流水线：输出数据
        dout <= mem_data_read;
    end
    
endmodule