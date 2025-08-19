//SystemVerilog
module ConditionalNOT(
    input wire clk,          
    input wire rst_n,        
    input wire [31:0] data,  
    output reg [31:0] result 
);
    // 内部信号优化
    reg [31:0] data_reg;
    
    // 第一级流水线 - 注册输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 32'h0;
        else
            data_reg <= data;
    end
    
    // 第二级流水线 - 直接在一个always块中完成逻辑判断
    // 避免额外的组合逻辑资源消耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 32'h0;
        else if (&data_reg) // 使用归约操作符检查是否所有位都为1，比较高效
            result <= 32'h0; 
        else
            result <= ~data_reg; // 直接反转，无需中间变量
    end
    
endmodule