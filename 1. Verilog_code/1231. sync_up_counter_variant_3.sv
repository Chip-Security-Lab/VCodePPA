//SystemVerilog
module sync_counter_up (
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [7:0] count
);
    // 优化计数器逻辑，添加明确的数据类型，改善时序和PPA
    reg enable_r;
    
    // 寄存enable信号以减少组合路径
    always @(posedge clk or posedge reset) begin
        if (reset)
            enable_r <= 1'b0;
        else
            enable_r <= enable;
    end
    
    // 使用pipeline方式处理计数逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 8'h00;
        else if (enable_r)
            count <= count + 8'h01;
    end
    
endmodule