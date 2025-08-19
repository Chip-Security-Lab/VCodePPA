//SystemVerilog
module therm2priority_encoder #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] thermometer_in,
    output reg  [$clog2(WIDTH)-1:0] priority_out,
    output wire valid_out
);
    // 使用OR-reduction来检查有效性
    assign valid_out = |thermometer_in;
    
    // 优化的单热码转换 (直接从温度计码获取单热码)
    wire [WIDTH-1:0] isolated_ones;
    
    // 优化Stage 1：使用差分法提取最低有效位的1
    // 利用 A & ~B = A ^ (A & B) 简化计算
    assign isolated_ones[0] = thermometer_in[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : isolate_opt
            assign isolated_ones[i] = thermometer_in[i] ^ thermometer_in[i-1];
        end
    endgenerate
    
    // 优化Stage 2：使用优先级编码器
    // 使用组合逻辑实现优先级编码，减少逻辑深度
    always @(*) begin
        priority_out = {$clog2(WIDTH){1'b0}};
        for (int j = WIDTH-1; j >= 0; j = j - 1) begin
            if (isolated_ones[j]) begin
                priority_out = j[$clog2(WIDTH)-1:0];
            end
        end
    end
endmodule