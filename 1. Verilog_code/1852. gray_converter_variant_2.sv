//SystemVerilog
// 二进制转格雷码子模块
module bin_to_gray #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    output [WIDTH-1:0] gray_out
);
    assign gray_out = bin_in ^ {1'b0, bin_in[WIDTH-1:1]};
endmodule

// 格雷码转二进制子模块
module gray_to_bin #(parameter WIDTH=4) (
    input [WIDTH-1:0] gray_in,
    output [WIDTH-1:0] bin_out
);
    genvar i;
    generate
        assign bin_out[WIDTH-1] = gray_in[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : gray_to_bin_gen
            assign bin_out[i] = ^gray_in[WIDTH-1:i];
        end
    endgenerate
endmodule

// 顶层模块
module gray_converter #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    input bin_to_gray,
    output [WIDTH-1:0] result
);
    wire [WIDTH-1:0] bin_to_gray_result;
    wire [WIDTH-1:0] gray_to_bin_result;
    
    bin_to_gray #(.WIDTH(WIDTH)) u_bin_to_gray (
        .bin_in(bin_in),
        .gray_out(bin_to_gray_result)
    );
    
    gray_to_bin #(.WIDTH(WIDTH)) u_gray_to_bin (
        .gray_in(bin_in),
        .bin_out(gray_to_bin_result)
    );
    
    assign result = bin_to_gray ? bin_to_gray_result : gray_to_bin_result;
endmodule