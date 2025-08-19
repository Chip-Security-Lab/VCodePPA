//SystemVerilog
module rom_clkdiv #(parameter MAX=50000000)(
    input clk,
    output reg clk_out
);
    // 优化计数器位宽，根据MAX参数自动计算所需位数
    localparam CNT_WIDTH = $clog2(MAX);
    reg [CNT_WIDTH-1:0] counter;
    
    // 使用比较优化的方式处理计数和分频
    always @(posedge clk) begin
        if(counter == MAX - 1) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // 初始化寄存器值（有助于仿真和某些FPGA工具）
    initial begin
        counter = 0;
        clk_out = 0;
    end
endmodule