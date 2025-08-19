//SystemVerilog
module counter_bcd (
    input wire clk,
    input wire rst,
    input wire en,
    output reg [3:0] bcd,
    output wire carry
);

    // 流水线阶段1：检测是否需要进位
    reg en_stage1;
    reg [3:0] bcd_stage1;
    reg carry_stage1;
    
    // 流水线阶段2：计算下一个值
    reg en_stage2;
    reg [3:0] next_bcd_stage2;
    reg carry_stage2;
    
    // 第一级流水线：保存输入并计算进位条件
    always @(posedge clk) begin
        if (rst) begin
            en_stage1 <= 1'b0;
            bcd_stage1 <= 4'd0;
            carry_stage1 <= 1'b0;
        end
        else begin
            en_stage1 <= en;
            bcd_stage1 <= bcd;
            carry_stage1 <= (bcd == 4'd9) & en;
        end
    end
    
    // Kogge-Stone加法器信号
    wire [3:0] operand_a;
    wire [3:0] operand_b;
    wire [3:0] ks_sum;
    
    // 设置加法器输入
    assign operand_a = bcd_stage1;
    assign operand_b = 4'd1;
    
    // 实例化Kogge-Stone加法器
    kogge_stone_adder #(
        .WIDTH(4)
    ) ks_adder_inst (
        .a(operand_a),
        .b(operand_b),
        .cin(1'b0),
        .sum(ks_sum),
        .cout()  // 不使用加法器的进位输出
    );
    
    // 第二级流水线：计算下一个BCD值
    always @(posedge clk) begin
        if (rst) begin
            en_stage2 <= 1'b0;
            next_bcd_stage2 <= 4'd0;
            carry_stage2 <= 1'b0;
        end
        else begin
            en_stage2 <= en_stage1;
            next_bcd_stage2 <= (bcd_stage1 == 4'd9) ? 4'd0 : ks_sum;
            carry_stage2 <= carry_stage1;
        end
    end
    
    // 最终输出阶段：将计算结果应用到输出
    always @(posedge clk) begin
        if (rst) begin
            bcd <= 4'd0;
        end
        else if (en_stage2) begin
            bcd <= next_bcd_stage2;
        end
    end
    
    // 进位输出
    assign carry = carry_stage2;

endmodule

module kogge_stone_adder #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // 第1步：计算传播和生成信号
    wire [WIDTH-1:0] p_init, g_init;
    assign p_init = a ^ b;
    assign g_init = a & b;
    
    // 第2步：计算组传播和组生成信号
    // 级联的第一级
    wire [WIDTH-1:0] p_lvl1, g_lvl1;
    
    assign g_lvl1[0] = g_init[0] | (p_init[0] & cin);
    assign p_lvl1[0] = p_init[0];
    
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : lvl1_gen
            assign g_lvl1[i] = g_init[i] | (p_init[i] & g_init[i-1]);
            assign p_lvl1[i] = p_init[i] & p_init[i-1];
        end
    endgenerate
    
    // 级联的第二级
    wire [WIDTH-1:0] p_lvl2, g_lvl2;
    
    assign g_lvl2[0] = g_lvl1[0];
    assign p_lvl2[0] = p_lvl1[0];
    assign g_lvl2[1] = g_lvl1[1];
    assign p_lvl2[1] = p_lvl1[1];
    
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : lvl2_gen
            assign g_lvl2[i] = g_lvl1[i] | (p_lvl1[i] & g_lvl1[i-2]);
            assign p_lvl2[i] = p_lvl1[i] & p_lvl1[i-2];
        end
    endgenerate
    
    // 计算进位信号
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            if (i == 0) begin
                assign carry[i+1] = g_lvl2[i];
            end else if (i == 1) begin
                assign carry[i+1] = g_lvl2[i] | (p_lvl2[i] & carry[0]);
            end else begin
                assign carry[i+1] = g_lvl2[i] | (p_lvl2[i] & carry[i-1]);
            end
        end
    endgenerate
    
    // 最终计算和
    assign sum = p_init ^ {carry[WIDTH-1:0]};
    assign cout = carry[WIDTH];
    
endmodule