//SystemVerilog
// 顶层模块
module bram_rom (
    input clk,
    input rst_n,  // 添加复位信号
    input valid_in,  // 输入有效信号
    input [3:0] addr,
    output [7:0] data,
    output valid_out  // 输出有效信号
);
    // 内部连线
    wire [7:0] rom_data;
    wire stage1_valid;
    
    // ROM存储单元子模块实例化
    rom_memory #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(4),
        .MEM_DEPTH(16)
    ) memory_unit (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .addr(addr),
        .data(rom_data),
        .valid_out(stage1_valid)
    );
    
    // 输出寄存器子模块实例化
    output_register #(
        .DATA_WIDTH(8)
    ) output_reg (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(stage1_valid),
        .data_in(rom_data),
        .data_out(data),
        .valid_out(valid_out)
    );
endmodule

// ROM存储单元子模块
module rom_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter MEM_DEPTH = 16
)(
    input clk,
    input rst_n,
    input valid_in,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data,
    output reg valid_out
);
    // 使用块RAM实现ROM存储
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:MEM_DEPTH-1];
    
    // 流水线寄存器
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg valid_stage1;
    
    // ROM数据初始化
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h00; rom[9] = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00;
        rom[12] = 8'h00; rom[13] = 8'h00; rom[14] = 8'h00; rom[15] = 8'h00;
    end
    
    // 第一级流水线：寄存地址和有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：读取ROM数据并传递有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 0;
            valid_out <= 1'b0;
        end else begin
            data <= rom[addr_stage1];
            valid_out <= valid_stage1;
        end
    end
endmodule

// 输出寄存器子模块
module output_register #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);
    // 注册输出数据和有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
endmodule