//SystemVerilog
module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // 内部信号声明
    reg [WIDTH-1:0] next_value;
    
    // 计算下一个波形值
    always @(*) begin
        if (wave_out < STEP) 
            next_value = {WIDTH{1'b1}}; // 防止下溢，重置到最大值
        else
            next_value = wave_out - STEP;
    end
    
    // 波形输出寄存器更新
    always @(posedge clk) begin
        if (rst) 
            wave_out <= {WIDTH{1'b1}}; // 复位时加载最大值
        else 
            wave_out <= next_value;
    end
endmodule