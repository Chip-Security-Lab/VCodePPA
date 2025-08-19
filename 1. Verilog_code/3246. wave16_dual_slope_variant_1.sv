//SystemVerilog
module wave16_dual_slope #(
    parameter WIDTH = 8,
    parameter UP_MAX = 200,
    parameter DOWN_MAX = 100
)(
    input  wire clk,
    input  wire rst,
    output reg [WIDTH-1:0] wave_out
);
    // 使用单比特标志来表示相位状态，而不是2比特寄存器
    reg up_phase;  
    
    // 预计算比较结果，减少关键路径延迟
    wire at_up_max = (wave_out == UP_MAX - 1);
    wire at_down_max = (wave_out == DOWN_MAX + 1);
    
    // 优化计数逻辑
    wire [WIDTH-1:0] next_value = up_phase ? (wave_out - 1'b1) : (wave_out + 1'b1);
    wire next_phase = (up_phase && at_down_max) || (!up_phase && at_up_max) ? ~up_phase : up_phase;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= DOWN_MAX;  // 从最小值开始，使波形更加稳定
            up_phase <= 1'b0;      // 从上升阶段开始
        end else begin
            wave_out <= next_value;
            up_phase <= next_phase;
        end
    end
endmodule