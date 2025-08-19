//SystemVerilog
// 顶层模块
module rom_dual_port #(
    parameter W = 32,
    parameter D = 1024,
    parameter ADDR_WIDTH = 10  // 参数化地址宽度
)(
    input  wire                   clk,
    input  wire [ADDR_WIDTH-1:0]  addr1,
    input  wire [ADDR_WIDTH-1:0]  addr2,
    output wire [W-1:0]           dout1,
    output wire [W-1:0]           dout2
);
    // 内部连线
    wire [W-1:0] mem_data1, mem_data2;
    
    // 实例化存储器控制模块
    rom_memory_core #(
        .DATA_WIDTH(W),
        .DEPTH(D),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_core_inst (
        .clk     (clk),
        .data_out1(mem_data1),
        .data_out2(mem_data2),
        .addr1   (addr1),
        .addr2   (addr2)
    );
    
    // 实例化输出寄存器模块
    output_register #(
        .WIDTH(W)
    ) output_reg_inst (
        .clk      (clk),
        .data_in1 (mem_data1),
        .data_in2 (mem_data2),
        .data_out1(dout1),
        .data_out2(dout2)
    );
    
endmodule

// 存储器核心模块
module rom_memory_core #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024,
    parameter ADDR_WIDTH = 10
)(
    input  wire                   clk,
    input  wire [ADDR_WIDTH-1:0]  addr1,
    input  wire [ADDR_WIDTH-1:0]  addr2,
    output reg  [DATA_WIDTH-1:0]  data_out1,
    output reg  [DATA_WIDTH-1:0]  data_out2
);
    // 存储器阵列
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    
    // 初始化存储器
    initial begin
        // 示例初始化，实际使用时可替换
        memory[0] = 32'h00001111;
        memory[1] = 32'h22223333;
        // $readmemh("dual_port.init", memory); // 实际应用中可启用
    end
    
    // 并行读取操作（无寄存）
    always @(posedge clk) begin
        data_out1 <= memory[addr1];
        data_out2 <= memory[addr2];
    end
    
endmodule

// 输出寄存器模块
module output_register #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire [WIDTH-1:0]  data_in1,
    input  wire [WIDTH-1:0]  data_in2,
    output reg  [WIDTH-1:0]  data_out1,
    output reg  [WIDTH-1:0]  data_out2
);
    // 寄存输出数据，改善时序
    always @(posedge clk) begin
        data_out1 <= data_in1;
        data_out2 <= data_in2;
    end
    
endmodule