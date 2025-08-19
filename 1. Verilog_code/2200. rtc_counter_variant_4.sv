//SystemVerilog
module rtc_counter #(
    parameter WIDTH = 32
)(
    input  wire             clk_i,
    input  wire             rst_i,
    input  wire             en_i,
    output reg              rollover_o,
    output wire [WIDTH-1:0] count_o
);
    reg [WIDTH-1:0] counter;
    wire counter_max;
    wire [WIDTH-1:0] next_counter;
    
    // 直接连接计数器输出
    assign count_o = counter;
    
    // 使用一个信号来检测计数器是否达到最大值
    assign counter_max = &counter;
    
    // 使用二进制补码减法算法实现递增逻辑
    // 当计数器达到最大值时，需要回到0
    // 即从全1减去全1得到0，否则从全1减去(~counter)得到counter+1
    assign next_counter = counter_max ? {WIDTH{1'b0}} : 
                         (({WIDTH{1'b1}}) - (~counter));
    
    // 控制信号组合
    reg [1:0] control;
    always @(*) begin
        control = {rst_i, en_i};
    end
    
    // 使用case语句替代if-else级联
    always @(posedge clk_i) begin
        case(control)
            2'b10, 2'b11: begin  // rst_i = 1, en_i = x
                counter <= {WIDTH{1'b0}};
                rollover_o <= 1'b0;
            end
            2'b01: begin  // rst_i = 0, en_i = 1
                counter <= next_counter;
                rollover_o <= counter_max;
            end
            2'b00: begin  // rst_i = 0, en_i = 0
                counter <= counter;
                rollover_o <= rollover_o;
            end
            default: begin
                counter <= counter;
                rollover_o <= rollover_o;
            end
        endcase
    end
endmodule