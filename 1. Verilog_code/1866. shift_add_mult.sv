module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] product
);
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] accum;
    reg [WIDTH-1:0] multiplicand;
    reg [2:0] state;
    reg [2:0] bit_count;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accum <= 0;
            multiplier <= b;
            multiplicand <= a;
            product <= 0;
            state <= 0;
            bit_count <= 0;
        end else begin
            case(state)
                0: begin // 初始状态
                    accum <= 0;
                    bit_count <= 0;
                    state <= 1;
                end
                
                1: begin // 检查位并在必要时添加
                    if (multiplier[0])
                        accum <= accum + (multiplicand << bit_count);
                    multiplier <= multiplier >> 1;
                    bit_count <= bit_count + 1;
                    
                    if (bit_count == WIDTH-1) state <= 2;
                end
                
                2: begin // 最终状态
                    product <= accum;
                    state <= 0;
                end
            endcase
        end
    end
endmodule