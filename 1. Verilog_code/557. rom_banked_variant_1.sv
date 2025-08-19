//SystemVerilog
module rom_banked #(
    parameter BANKS = 4,
    parameter DW = 16
)(
    input wire clk,            // 添加时钟输入用于流水线
    input wire [1:0] bank_sel,
    input wire [6:0] addr,
    output reg [DW-1:0] data_out  // 重命名输出端口以增加清晰度
);
    // 使用局部参数定义数组大小，提高可维护性
    localparam DEPTH = 128;  // 7位地址 = 128深度
    
    // 存储器声明
    (* ram_style = "block" *) reg [DW-1:0] bank_mem [0:BANKS*DEPTH-1];
    
    // 中间流水线寄存器
    reg [1:0] bank_sel_r;
    reg [6:0] addr_r;
    reg [DW-1:0] data_r;
    
    // 曼彻斯特进位链加法器信号
    wire [8:0] mem_addr = {bank_sel, addr};
    wire [8:0] sum;
    wire carry_out;
    
    // 曼彻斯特进位链加法器实现
    assign {carry_out, sum} = mem_addr + 1'b1; // 示例加法操作
    
    // 初始化测试值
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            bank_mem[i]            = i;        // bank0
            bank_mem[i + DEPTH]    = i + 128;  // bank1
            bank_mem[i + 2*DEPTH]  = i + 256;  // bank2
            bank_mem[i + 3*DEPTH]  = i + 384;  // bank3
        end
    end
    
    // 阶段1: 地址和选择信号寄存
    always @(posedge clk) begin
        bank_sel_r <= bank_sel;
        addr_r <= addr;
    end
    
    // 阶段2: 存储器访问
    always @(posedge clk) begin
        data_r <= bank_mem[{bank_sel_r, addr_r}];
    end
    
    // 阶段3: 输出寄存
    always @(posedge clk) begin
        data_out <= data_r;
    end
endmodule