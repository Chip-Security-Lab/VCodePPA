//SystemVerilog
module clk_gate_pipeline #(parameter STAGES=2) (
    input wire clk, en, in,
    output reg out
);
    reg [STAGES:0] pipe;
    wire [7:0] stage_data;
    wire [7:0] complement_data;
    wire [7:0] subtraction_result;
    
    // 对输入数据进行处理，应用二进制补码减法算法
    assign stage_data = {8{in}};
    assign complement_data = ~stage_data + 8'b1; // 二进制补码
    assign subtraction_result = stage_data - complement_data;
    
    always @(posedge clk) begin
        if(en) begin
            // 使用减法结果控制管道移位
            if(subtraction_result[7]) // 检查符号位
                pipe <= {pipe[STAGES-1:0], in};
            else
                pipe <= {pipe[STAGES-1:0], ~in};
        end
        out <= pipe[STAGES];
    end
endmodule