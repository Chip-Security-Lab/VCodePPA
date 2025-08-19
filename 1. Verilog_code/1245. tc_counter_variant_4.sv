//SystemVerilog
module tc_counter #(parameter WIDTH = 8) (
    input wire clock, clear, enable,
    output reg [WIDTH-1:0] counter,
    output reg tc
);
    // 预计算下一个状态值
    wire [WIDTH-1:0] next_counter = counter + 1'b1;
    wire counter_max = &counter;
    
    // 时序逻辑 - 使用寄存器捕获tc信号减少组合逻辑延迟
    always @(posedge clock) begin
        if (clear) begin
            counter <= {WIDTH{1'b0}};
            tc <= 1'b0;
        end else if (enable) begin
            counter <= next_counter;
            tc <= counter_max; // 在计数器更新前检测最大值
        end else begin
            tc <= 1'b0; // 当enable无效时确保tc为0
        end
    end
endmodule