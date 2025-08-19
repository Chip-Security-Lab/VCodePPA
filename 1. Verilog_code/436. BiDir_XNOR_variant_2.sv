//SystemVerilog
module BiDir_XNOR(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    // 使用XNOR运算符(~^)替代取反的XOR
    // 这减少了逻辑门数量并改善时序
    wire [7:0] xnor_result;
    reg [7:0] bus_a_out, bus_b_out;
    reg [7:0] bus_a_en, bus_b_en;
    
    assign xnor_result = bus_a ~^ bus_b;
    
    // 使用if-else结构替代条件运算符
    always @(*) begin
        if (dir) begin
            bus_a_out = xnor_result;
            bus_a_en = 8'hff;
            bus_b_out = 8'h00;
            bus_b_en = 8'h00;
        end else begin
            bus_a_out = 8'h00;
            bus_a_en = 8'h00;
            bus_b_out = xnor_result;
            bus_b_en = 8'hff;
        end
    end
    
    // 使用enable信号控制三态输出
    assign bus_a = bus_a_en ? bus_a_out : 8'hzz;
    assign bus_b = bus_b_en ? bus_b_out : 8'hzz;
    
    // 直接连接总线A到结果
    assign result = bus_a;
endmodule