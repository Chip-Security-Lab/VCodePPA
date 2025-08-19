//SystemVerilog
// 组合逻辑模块
module SARDiv_Comb(
    input [7:0] rem,
    input [7:0] d,
    output [7:0] shifted_rem,
    output can_subtract,
    output [7:0] sub_result,
    output borrow_out
);
    // 预计算移位结果
    assign shifted_rem = rem << 1;
    
    // 判断是否可以减法
    assign can_subtract = (shifted_rem >= d && d != 0);
    
    // 借位减法器实例化
    BorrowSubtractor subtractor(
        .a(shifted_rem),
        .b(d),
        .bin(1'b0),
        .diff(sub_result),
        .bout(borrow_out)
    );
endmodule

// 时序逻辑模块
module SARDiv_Seq(
    input clk,
    input start,
    input [7:0] D,
    input [7:0] d,
    input [7:0] sub_result,
    input can_subtract,
    output reg [7:0] q,
    output reg done
);
    reg [7:0] rem;
    reg [3:0] bit_cnt;
    
    // 初始化状态
    always @(posedge clk) begin
        if(start) begin
            rem <= D;
            bit_cnt <= 7;
            q <= 0;
            done <= 0;
        end
    end

    // 处理位计算和结果更新
    always @(posedge clk) begin
        if(bit_cnt <= 7) begin
            if(can_subtract) begin
                rem <= sub_result;
                q[bit_cnt] <= 1'b1;
            end else begin
                rem <= (rem << 1);
            end
            
            if(bit_cnt == 0)
                done <= 1;
            else
                bit_cnt <= bit_cnt - 1;
        end
    end
endmodule

// 顶层模块
module SARDiv(
    input clk,
    input start,
    input [7:0] D,
    input [7:0] d,
    output [7:0] q,
    output done
);
    wire [7:0] shifted_rem;
    wire can_subtract;
    wire [7:0] sub_result;
    wire borrow_out;
    
    // 组合逻辑实例化
    SARDiv_Comb comb_logic(
        .rem(rem),
        .d(d),
        .shifted_rem(shifted_rem),
        .can_subtract(can_subtract),
        .sub_result(sub_result),
        .borrow_out(borrow_out)
    );
    
    // 时序逻辑实例化
    SARDiv_Seq seq_logic(
        .clk(clk),
        .start(start),
        .D(D),
        .d(d),
        .sub_result(sub_result),
        .can_subtract(can_subtract),
        .q(q),
        .done(done)
    );
endmodule

// 8位借位减法器模块保持不变
module BorrowSubtractor(
    input [7:0] a,
    input [7:0] b,
    input bin,
    output [7:0] diff,
    output bout
);
    wire [8:0] borrows;
    assign borrows[0] = bin;
    
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin: borrow_sub_bit
            assign diff[i] = a[i] ^ b[i] ^ borrows[i];
            assign borrows[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrows[i]);
        end
    endgenerate
    
    assign bout = borrows[8];
endmodule