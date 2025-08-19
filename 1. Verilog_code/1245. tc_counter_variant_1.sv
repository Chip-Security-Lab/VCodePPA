//SystemVerilog
module tc_counter #(parameter WIDTH = 8) (
    input wire clock,
    input wire clear,
    input wire enable,
    output reg [WIDTH-1:0] counter,
    output wire tc
);
    // 终端计数逻辑优化：使用向量比较代替位与运算
    // 对所有位为1的情况进行直接比较，并与enable相与
    assign tc = (counter == {WIDTH{1'b1}}) && enable;
    
    // 合并计数器逻辑，减少always块数量，优化时序路径
    always @(posedge clock) begin
        if (clear) begin
            counter <= {WIDTH{1'b0}};
        end else if (enable) begin
            counter <= counter + 1'b1;
        end
    end
endmodule