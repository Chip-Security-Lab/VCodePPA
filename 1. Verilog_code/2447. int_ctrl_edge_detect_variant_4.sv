//SystemVerilog
module int_ctrl_edge_detect #(WIDTH=8)(
    input clk,
    input [WIDTH-1:0] async_int,
    output [WIDTH-1:0] edge_out
);
    reg [WIDTH-1:0] sync_reg, prev_reg;
    wire [WIDTH-1:0] cond_sub_result;
    wire [WIDTH-1:0] borrow;
    
    always @(posedge clk) begin
        prev_reg <= sync_reg;
        sync_reg <= async_int;
    end
    
    // 使用条件求和减法算法实现 sync_reg & ~prev_reg
    // 这等价于 sync_reg & (~prev_reg)，可看作 sync_reg 与 prev_reg 取反的按位与
    // 实现方式：使用条件求和减法算法检测 sync_reg 中为1且 prev_reg 中为0的位
    
    // 生成借位信号
    assign borrow[0] = ~sync_reg[0] & prev_reg[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i] = (~sync_reg[i] & prev_reg[i]) | 
                              (~sync_reg[i] & borrow[i-1]) | 
                              (prev_reg[i] & borrow[i-1]);
        end
    endgenerate
    
    // 条件求和减法的结果
    assign cond_sub_result = sync_reg ^ prev_reg ^ {borrow[WIDTH-2:0], 1'b0};
    
    // 最终结果：仅保留 sync_reg 为1且 prev_reg 为0的位
    assign edge_out = sync_reg & cond_sub_result;
    
endmodule