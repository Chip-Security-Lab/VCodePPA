//SystemVerilog
module BiDir_NAND(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    reg [7:0] bus_a_out, bus_b_out;
    reg [7:0] nand_result;
    
    // 计算NAND结果
    always @(*) begin
        nand_result = ~(bus_a & bus_b);
    end
    
    // 根据dir控制总线方向
    always @(*) begin
        if (dir) begin
            bus_a_out = nand_result;
            bus_b_out = 8'hzz;
        end else begin
            bus_a_out = 8'hzz;
            bus_b_out = nand_result;
        end
    end
    
    // 分配到输出和总线
    assign bus_a = bus_a_out;
    assign bus_b = bus_b_out;
    assign result = nand_result;
    
endmodule