//SystemVerilog
module even_divider #(
    parameter DIV_WIDTH = 8,
    parameter DIV_VALUE = 10
)(
    input clk_in,
    input rst_n,
    output reg clk_out
);
    reg [DIV_WIDTH-1:0] counter;
    reg [DIV_WIDTH-1:0] next_counter;
    reg next_clk_out;
    
    // 显式多路复用器结构
    always @(*) begin
        if (counter == DIV_VALUE-1) begin
            next_counter = 0;
        end else begin
            next_counter = counter + 1;
        end
        
        if (counter < (DIV_VALUE>>1)) begin
            next_clk_out = 1'b0;
        end else begin
            next_clk_out = 1'b1;
        end
    end
    
    // 寄存器更新
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= next_counter;
            clk_out <= next_clk_out;
        end
    end
endmodule