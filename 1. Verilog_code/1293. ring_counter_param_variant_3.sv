//SystemVerilog
module ring_counter_param #(parameter WIDTH=4) (
    input clk, rst,
    output reg [WIDTH-1:0] counter_reg
);
    reg [WIDTH-1:0] next_state;
    wire [WIDTH-1:0] subtracted_value;
    wire [WIDTH-1:0] complemented_value;
    
    // 使用二进制补码减法算法
    assign complemented_value = ~counter_reg + 1'b1;
    assign subtracted_value = {counter_reg[0], counter_reg[WIDTH-1:1]};
    
    always @(*) begin
        if (rst)
            next_state = {{WIDTH-1{1'b0}}, 1'b1};
        else if (counter_reg == 0)
            next_state = {{WIDTH-1{1'b0}}, 1'b1};
        else
            next_state = subtracted_value ^ complemented_value;
    end
    
    always @(posedge clk) begin
        if (rst)
            counter_reg <= {{WIDTH-1{1'b0}}, 1'b1};
        else
            counter_reg <= next_state;
    end
endmodule