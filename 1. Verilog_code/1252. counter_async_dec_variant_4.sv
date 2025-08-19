//SystemVerilog
module counter_async_dec #(parameter WIDTH=8) (
    input clk, rst, en,
    output reg [WIDTH-1:0] count
);
    wire [WIDTH-1:0] next_count;
    
    // 简化的异步递减逻辑
    // 借位计算简化：~count[i] | borrow[i]
    // 下一个计数值简化：count[i] ^ (borrow[i] | 1'b1) = count[i] ^ 1'b1 = ~count[i]
    
    assign next_count = count - 1'b1;
    
    always @(posedge clk, posedge rst) begin
        if (rst) 
            count <= {WIDTH{1'b1}};
        else if (en) 
            count <= next_count;
    end
endmodule