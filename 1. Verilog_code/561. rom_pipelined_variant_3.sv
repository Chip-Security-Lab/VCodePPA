//SystemVerilog
module rom_pipelined_han_carlson #(parameter STAGES=2)(
    input clk,
    input [9:0] addr_in,
    output [7:0] data_out
);
    // 声明内部信号
    reg [9:0] pipe_addr [0:STAGES-1];
    reg [7:0] pipe_data [0:STAGES-1];
    reg [7:0] mem [0:1023];
    
    wire [7:0] mem_data;  // 组合逻辑输出信号
    wire [9:0] sum;        // Han-Carlson加法器输出
    wire [9:0] carry;      // 进位信号

    integer i;
    
    // 初始化存储器
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = i & 8'hFF; // 测试模式
    end
    
    // Han-Carlson加法器实现
    assign {carry, sum} = pipe_addr[0] + addr_in; // 使用加法器计算和与进位
    assign mem_data = mem[sum[9:0]]; // 使用计算结果访问存储器
    
    // 时序逻辑：地址和数据管线
    always @(posedge clk) begin
        // 地址管线移位
        pipe_addr[0] <= addr_in;
        for(i = 1; i < STAGES; i = i + 1)
            pipe_addr[i] <= pipe_addr[i-1];
            
        // 数据管线移位，从组合逻辑获取第一级数据
        pipe_data[0] <= mem_data;
        for(i = 1; i < STAGES; i = i + 1)
            pipe_data[i] <= pipe_data[i-1];
    end
    
    // 输出赋值（组合逻辑）
    assign data_out = pipe_data[STAGES-1];
endmodule