//SystemVerilog
module modulo_counter #(parameter MOD_VALUE = 10, WIDTH = 4) (
    input wire clk, reset,
    output reg [WIDTH-1:0] count,
    output wire tc
);
    wire [WIDTH-1:0] compare_value;
    wire [WIDTH:0] borrow;
    
    assign compare_value = MOD_VALUE - 1'b1;
    
    // 借位减法器实现比较逻辑
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_gen
            assign borrow[i+1] = (~count[i] & compare_value[i]) | 
                               (~count[i] & borrow[i]) | 
                               (compare_value[i] & borrow[i]);
        end
    endgenerate
    
    // 如果没有借位，则表示count >= compare_value
    assign tc = ~borrow[WIDTH];
    
    always @(posedge clk) begin
        if (reset)
            count <= {WIDTH{1'b0}};
        else
            count <= tc ? {WIDTH{1'b0}} : count + 1'b1;
    end
endmodule