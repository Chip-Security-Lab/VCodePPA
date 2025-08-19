//SystemVerilog
module fifo_parity #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] fifo [0:DEPTH-1]
);
    wire parity_bit;
    integer i;
    
    // Brent-Kung加法器用于计算奇偶校验位
    brent_kung_parity #(
        .WIDTH(WIDTH)
    ) parity_generator (
        .data_in(data_in),
        .parity_out(parity_bit)
    );
    
    always @(posedge clk) begin
        if (wr_en) begin
            fifo[0] <= {parity_bit, data_in};
            for (i=1; i<DEPTH; i=i+1)
                fifo[i] <= fifo[i-1];
        end
    end
endmodule

module brent_kung_parity #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output parity_out
);
    // Brent-Kung树形结构计算奇偶校验
    // 第一阶段：生成传播信号
    wire [WIDTH-1:0] p_stage1;
    genvar i;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_stage1
            assign p_stage1[i] = data_in[i];
        end
    endgenerate
    
    // 第二阶段：2位组合
    wire [WIDTH/2-1:0] p_stage2;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: gen_stage2
            assign p_stage2[i] = p_stage1[2*i] ^ p_stage1[2*i+1];
        end
    endgenerate
    
    // 第三阶段：4位组合
    wire [WIDTH/4-1:0] p_stage3;
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin: gen_stage3
            assign p_stage3[i] = p_stage2[2*i] ^ p_stage2[2*i+1];
        end
    endgenerate
    
    // 第四阶段：8位组合（最终奇偶校验结果）
    wire p_final = p_stage3[0] ^ p_stage3[1];
    
    assign parity_out = p_final;
endmodule