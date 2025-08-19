//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005
module async_arbiter #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // 内部连接信号
    wire [WIDTH-1:0] neg_req;
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] result;
    wire [WIDTH-1:0] mask;

    // 子模块实例化
    req_inverter #(
        .WIDTH(WIDTH)
    ) req_inv_inst (
        .req_i(req_i),
        .neg_req_o(neg_req)
    );

    borrow_generator #(
        .WIDTH(WIDTH)
    ) borrow_gen_inst (
        .req_i(req_i),
        .borrow_o(borrow)
    );

    subtractor #(
        .WIDTH(WIDTH)
    ) sub_inst (
        .neg_req_i(neg_req),
        .borrow_i(borrow),
        .result_o(result)
    );

    mask_generator #(
        .WIDTH(WIDTH)
    ) mask_gen_inst (
        .req_i(req_i),
        .result_i(result),
        .grant_o(grant_o)
    );

endmodule

//IEEE 1364-2005
module req_inverter #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] neg_req_o
);
    // 取反请求信号获得被减数的补码
    assign neg_req_o = ~req_i;
endmodule

//IEEE 1364-2005
module borrow_generator #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] borrow_o
);
    // 先行借位逻辑计算
    reg [WIDTH-1:0] borrow_temp;
    
    always @* begin
        borrow_temp[0] = 1'b1; // 初始借位为1，实现+1操作
        for (integer i = 0; i < WIDTH-1; i = i + 1) begin
            borrow_temp[i+1] = (~req_i[i] & borrow_temp[i]);
        end
    end
    
    assign borrow_o = borrow_temp;
endmodule

//IEEE 1364-2005
module subtractor #(parameter WIDTH=4) (
    input [WIDTH-1:0] neg_req_i,
    input [WIDTH-1:0] borrow_i,
    output [WIDTH-1:0] result_o
);
    // 使用先行借位进行减法计算
    reg [WIDTH-1:0] result_temp;
    
    always @* begin
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            result_temp[i] = neg_req_i[i] ^ borrow_i[i];
        end
    end
    
    assign result_o = result_temp;
endmodule

//IEEE 1364-2005
module mask_generator #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] result_i,
    output [WIDTH-1:0] grant_o
);
    // 计算掩码并生成grant信号
    assign grant_o = req_i & result_i;
endmodule