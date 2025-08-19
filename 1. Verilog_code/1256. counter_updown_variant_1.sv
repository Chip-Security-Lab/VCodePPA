//SystemVerilog
module counter_updown #(parameter WIDTH=4) (
    input clk, rst, dir, en,
    output reg [WIDTH-1:0] cnt
);
    wire [WIDTH-1:0] next_cnt;
    wire [WIDTH-1:0] add_result;
    wire [WIDTH-1:0] sub_result;
    
    // 加法逻辑
    assign add_result = cnt + 1'b1;
    
    // 先行借位减法器实现
    parallel_borrow_subtractor #(.WIDTH(WIDTH)) sub_inst (
        .a(cnt),
        .b(8'h01),
        .diff(sub_result)
    );
    
    // 选择增加或减少
    assign next_cnt = dir ? add_result : sub_result;
    
    // 更新计数器
    always @(posedge clk) begin
        if (rst) cnt <= {WIDTH{1'b0}};
        else if (en) cnt <= next_cnt;
    end
endmodule

// 先行借位减法器模块
module parallel_borrow_subtractor #(parameter WIDTH=4) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH:0] borrow;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 生成每一位的借位和差
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow
            // 当前位的差
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
            // 下一位的借位
            assign borrow[i+1] = (~a[i] & b[i]) | (borrow[i] & ~(a[i] ^ b[i]));
        end
    endgenerate
endmodule