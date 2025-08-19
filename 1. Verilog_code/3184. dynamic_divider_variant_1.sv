//SystemVerilog
module dynamic_divider #(
    parameter CTR_WIDTH = 8
)(
    input clk,
    input [CTR_WIDTH-1:0] div_value,
    input load,
    output reg clk_div
);
    reg [CTR_WIDTH-1:0] counter;
    reg [CTR_WIDTH-1:0] current_div;
    wire comparison_flag;
    
    // 使用比较器实现比较功能，提高效率
    assign comparison_flag = (counter >= (current_div - 1'b1));
    
    always @(posedge clk) begin
        // 更新分频值
        if (load) begin
            current_div <= div_value;
        end else begin
            current_div <= current_div;
        end
        
        // 使用if-else结构替代条件运算符
        if (comparison_flag) begin
            counter <= 0;
            clk_div <= ~clk_div;
        end else begin
            counter <= counter + 1'b1;
            clk_div <= clk_div;
        end
    end
endmodule