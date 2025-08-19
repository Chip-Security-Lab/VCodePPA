//SystemVerilog
module duty_cycle_clock #(
    parameter WIDTH = 8
)(
    input wire clkin,
    input wire reset,
    input wire [WIDTH-1:0] high_time,
    input wire [WIDTH-1:0] low_time,
    output reg clkout
);
    reg [WIDTH-1:0] counter = 0;
    reg [WIDTH-1:0] target_time;
    reg [WIDTH-1:0] target_time_reg; // 注册target_time以切割路径
    wire [WIDTH-1:0] diff;
    wire borrow;
    
    // 分段计算：先注册target_time，然后在下一个时钟周期使用
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            target_time_reg <= 0;
        end else begin
            target_time_reg <= clkout ? high_time : low_time;
        end
    end
    
    // 使用注册后的target_time_reg进行比较计算
    assign {borrow, diff} = {1'b0, counter} + {1'b0, ~target_time_reg} + 1'b1;
    
    // 移除组合逻辑，直接使用注册信号
    always @(*) begin
        target_time = clkout ? high_time : low_time;
    end
    
    // 优化状态更新逻辑
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkout <= 0;
        end else begin
            if (~borrow) begin  // 当counter >= target_time_reg时
                counter <= 0;
                clkout <= ~clkout;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule