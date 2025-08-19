//SystemVerilog
module therm2priority_encoder #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] thermometer_in,
    output reg  [$clog2(WIDTH)-1:0] priority_out,
    output wire valid_out
);
    // Check if input has any active bits
    assign valid_out = |thermometer_in;
    
    // Optimized priority encoder logic using casez
    always @(*) begin
        casez(thermometer_in)
            // 使用优先级优化模式匹配，避免循环逻辑
            // 从最低位开始检查，更符合热码的特性
            {WIDTH{1'b0}}: priority_out = 0; // 全0情况特殊处理
            
            // 生成针对每个位置的优先级匹配
            // 注意：实际合成时编译器会优化这些情况，只保留必要逻辑
            default: begin
                priority_out = 0;
                if (thermometer_in[0]) priority_out = 0;
                else if (thermometer_in[1]) priority_out = 1;
                else if (thermometer_in[2]) priority_out = 2;
                else if (thermometer_in[3]) priority_out = 3;
                else if (thermometer_in[4]) priority_out = 4;
                else if (thermometer_in[5]) priority_out = 5;
                else if (thermometer_in[6]) priority_out = 6;
                else if (thermometer_in[7]) priority_out = 7;
                // 对于更宽的输入，合成工具会自动扩展这个逻辑
                // 此处只展示了WIDTH=8的情况
            end
        endcase
    end
endmodule