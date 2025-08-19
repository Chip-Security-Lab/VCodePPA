//SystemVerilog
module SignExtender #(parameter WIDTH=4)(
    input [WIDTH-1:0] data,
    output signed [WIDTH:0] extended_data
);
    assign extended_data = {data[WIDTH-1], data};
endmodule

module SignedMultiplier #(parameter WIDTH=4)(
    input signed [WIDTH:0] x,
    input signed [WIDTH:0] y,
    output signed [2*WIDTH+1:0] product
);
    assign product = x * y;
endmodule

module ResultSelector #(parameter WIDTH=4)(
    input signed [2*WIDTH+1:0] product_signed,
    output [2*WIDTH-1:0] final_product
);
    assign final_product = product_signed[2*WIDTH-1:0];
endmodule

module Multiplier2 #(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);
    wire signed [WIDTH:0] x_ext;
    wire signed [WIDTH:0] y_ext;
    wire signed [2*WIDTH+1:0] product_signed;

    SignExtender #(WIDTH) x_extender(.data(x), .extended_data(x_ext));
    SignExtender #(WIDTH) y_extender(.data(y), .extended_data(y_ext));
    SignedMultiplier #(WIDTH) multiplier(.x(x_ext), .y(y_ext), .product(product_signed));
    ResultSelector #(WIDTH) selector(.product_signed(product_signed), .final_product(product));
endmodule