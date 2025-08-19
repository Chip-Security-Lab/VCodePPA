// 顶层模块 - 4位减法器
module Sub4(
    input [3:0] x,
    input [3:0] y,
    output [3:0] diff,
    output borrow
);
    // 实例化4位减法器核心模块
    Sub4Core sub4_core(
        .x(x),
        .y(y),
        .diff(diff),
        .borrow(borrow)
    );
endmodule

// 4位减法器核心模块
module Sub4Core(
    input [3:0] x,
    input [3:0] y,
    output [3:0] diff,
    output borrow
);
    wire [3:0] borrow_wire;
    
    // 实例化4个全减法器
    FullSubtractor fs0(
        .a(x[0]),
        .b(y[0]),
        .borrow_in(1'b0),
        .diff(diff[0]),
        .borrow_out(borrow_wire[0])
    );
    
    FullSubtractor fs1(
        .a(x[1]),
        .b(y[1]),
        .borrow_in(borrow_wire[0]),
        .diff(diff[1]),
        .borrow_out(borrow_wire[1])
    );
    
    FullSubtractor fs2(
        .a(x[2]),
        .b(y[2]),
        .borrow_in(borrow_wire[1]),
        .diff(diff[2]),
        .borrow_out(borrow_wire[2])
    );
    
    FullSubtractor fs3(
        .a(x[3]),
        .b(y[3]),
        .borrow_in(borrow_wire[2]),
        .diff(diff[3]),
        .borrow_out(borrow)
    );
endmodule

// 全减法器模块
module FullSubtractor(
    input a,
    input b,
    input borrow_in,
    output diff,
    output borrow_out
);
    // 使用查找表优化全减法器逻辑
    reg diff_reg, borrow_out_reg;
    
    always @(*) begin
        case({a, b, borrow_in})
            3'b000: begin diff_reg = 0; borrow_out_reg = 0; end
            3'b001: begin diff_reg = 1; borrow_out_reg = 1; end
            3'b010: begin diff_reg = 1; borrow_out_reg = 1; end
            3'b011: begin diff_reg = 0; borrow_out_reg = 1; end
            3'b100: begin diff_reg = 1; borrow_out_reg = 0; end
            3'b101: begin diff_reg = 0; borrow_out_reg = 0; end
            3'b110: begin diff_reg = 0; borrow_out_reg = 0; end
            3'b111: begin diff_reg = 1; borrow_out_reg = 1; end
        endcase
    end
    
    assign diff = diff_reg;
    assign borrow_out = borrow_out_reg;
endmodule