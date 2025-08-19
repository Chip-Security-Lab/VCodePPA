//SystemVerilog
module rtc_counter #(
    parameter WIDTH = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg rollover_o,
    output wire [WIDTH-1:0] count_o
);
    reg [WIDTH-1:0] counter;
    wire counter_full;
    
    // 针对8位减法器的查找表辅助实现
    reg [7:0] lut_sub_result;
    reg [8:0] subtrahend;
    reg [7:0] lut_values [0:255];
    
    // 查找表初始化
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_values[i] = 8'd255 - i;
        end
    end
    
    assign count_o = counter;
    assign counter_full = &counter;
    
    always @(*) begin
        subtrahend = counter_full ? 9'd0 : 9'd255;
        lut_sub_result = lut_values[subtrahend[7:0]];
    end
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {WIDTH{1'b0}};
            rollover_o <= 1'b0;
        end else if (en_i) begin
            // 使用查找表实现的减法运算来辅助计数器更新
            // 当counter_full为真时，将计数器置为0
            // 否则使用查找表执行 (255 - subtrahend) + 1 = 256 - subtrahend
            // 这与 counter + 1 功能等价
            counter <= counter_full ? {WIDTH{1'b0}} : counter + (lut_sub_result + 1'b1 - subtrahend[8]);
            rollover_o <= counter_full;
        end
    end
endmodule