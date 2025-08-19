//SystemVerilog
module Multiplier2#(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);
    reg [2*WIDTH-1:0] product_reg;
    reg [2*WIDTH-1:0] partial_sum;
    reg [WIDTH-1:0] multiplier;
    integer i;
    
    always @(*) begin
        partial_sum = 0;
        multiplier = y;
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (multiplier[0]) begin
                case(i)
                    0: partial_sum = partial_sum + x;
                    1: partial_sum = partial_sum + {x, 1'b0};
                    2: partial_sum = partial_sum + {x, 2'b0};
                    3: partial_sum = partial_sum + {x, 3'b0};
                    default: partial_sum = partial_sum + (x << i);
                endcase
            end
            multiplier = multiplier >> 1;
        end
        
        product_reg = partial_sum;
    end
    
    assign product = product_reg;
endmodule