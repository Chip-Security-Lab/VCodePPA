//SystemVerilog
module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    wire [WIDTH-1:0] next_value;
    
    brent_kung_adder #(.WIDTH(WIDTH)) bk_adder (
        .a(wave_out),
        .b({{(WIDTH-1){1'b0}}, 1'b1}),
        .sum(next_value)
    );

    always @(posedge clk or posedge rst) begin
        if(rst) wave_out <= 0;
        else    wave_out <= next_value;
    end
endmodule

module brent_kung_adder #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0] carry;
    
    // 阶段1：生成传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 阶段2：计算群组传播和生成（Brent-Kung树）
    wire [WIDTH-1:0] pp, gg; // 第一级
    wire [WIDTH-1:0] ppp, ggg; // 第二级
    
    // 第一级: 2位组
    generate
        for (i = 1; i < WIDTH; i = i + 2) begin : group_level1
            if (i+1 < WIDTH) begin
                assign pp[i] = p[i] & p[i-1];
                assign gg[i] = g[i] | (p[i] & g[i-1]);
            end
        end
    endgenerate
    
    // 第二级: 4位组
    generate
        for (i = 3; i < WIDTH; i = i + 4) begin : group_level2
            if (i+1 < WIDTH) begin
                assign ppp[i] = pp[i] & pp[i-2];
                assign ggg[i] = gg[i] | (pp[i] & gg[i-2]);
            end
        end
    endgenerate
    
    // 阶段3：计算进位
    assign carry[0] = 1'b0; // 无进位输入
    
    // 直接使用各级的结果计算进位
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_carry
            if (i % 4 == 0 && i+1 < WIDTH)
                assign carry[i] = ggg[i-1];
            else if (i % 2 == 0 && i+1 < WIDTH)
                assign carry[i] = gg[i-1];
            else if (i == 1)
                assign carry[i] = g[0];
            else if (i % 4 == 1 && i > 1)
                assign carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
            else if (i % 4 == 2)
                assign carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
            else if (i % 4 == 3)
                assign carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
        end
    endgenerate
    
    // 阶段4：计算和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
    
endmodule