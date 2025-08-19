//SystemVerilog
module priority_arbiter(
    input wire clk,
    input wire reset,
    input wire [3:0] requests,
    output reg [3:0] grant,
    output reg busy,
    // 新增乘法器接口
    input wire [3:0] multiplicand,
    input wire [3:0] multiplier,
    output reg [7:0] product
);
    parameter [1:0] IDLE = 2'b00, GRANT0 = 2'b01, GRANT1 = 2'b10, GRANT2 = 2'b11;
    reg [1:0] state, next_state;
    
    // Dadda乘法器信号定义
    wire [3:0] pp0, pp1, pp2, pp3;
    wire [5:0] s1_sum1, s1_sum2;
    wire [6:0] s2_sum;
    wire [7:0] dadda_product;
    
    // 生成部分积
    assign pp0 = multiplier[0] ? multiplicand : 4'b0000;
    assign pp1 = multiplier[1] ? {multiplicand, 1'b0} : 5'b00000;
    assign pp2 = multiplier[2] ? {multiplicand, 2'b00} : 6'b000000;
    assign pp3 = multiplier[3] ? {multiplicand, 3'b000} : 7'b0000000;
    
    // Dadda第一级压缩
    wire s1_c1, s1_c2, s1_c3, s1_c4, s1_c5;
    
    // 第一级压缩 - 采用全加器和半加器
    half_adder ha1(.a(pp0[1]), .b(pp1[0]), .sum(s1_sum1[0]), .cout(s1_c1));
    full_adder fa1(.a(pp0[2]), .b(pp1[1]), .cin(pp2[0]), .sum(s1_sum1[1]), .cout(s1_c2));
    full_adder fa2(.a(pp0[3]), .b(pp1[2]), .cin(pp2[1]), .sum(s1_sum1[2]), .cout(s1_c3));
    full_adder fa3(.a(pp1[3]), .b(pp2[2]), .cin(pp3[1]), .sum(s1_sum1[3]), .cout(s1_c4));
    half_adder ha2(.a(pp2[3]), .b(pp3[2]), .sum(s1_sum1[4]), .cout(s1_c5));
    assign s1_sum1[5] = pp3[3];
    
    assign s1_sum2[0] = s1_c1;
    assign s1_sum2[1] = s1_c2;
    assign s1_sum2[2] = s1_c3;
    assign s1_sum2[3] = s1_c4;
    assign s1_sum2[4] = s1_c5;
    assign s1_sum2[5] = 1'b0;
    
    // Dadda第二级压缩
    wire s2_c1, s2_c2, s2_c3, s2_c4, s2_c5, s2_c6;
    
    assign s2_sum[0] = pp0[0];
    half_adder ha3(.a(s1_sum1[0]), .b(1'b0), .sum(s2_sum[1]), .cout(s2_c1));
    half_adder ha4(.a(s1_sum1[1]), .b(s1_sum2[0]), .sum(s2_sum[2]), .cout(s2_c2));
    full_adder fa4(.a(s1_sum1[2]), .b(s1_sum2[1]), .cin(s2_c1), .sum(s2_sum[3]), .cout(s2_c3));
    full_adder fa5(.a(s1_sum1[3]), .b(s1_sum2[2]), .cin(s2_c2), .sum(s2_sum[4]), .cout(s2_c4));
    full_adder fa6(.a(s1_sum1[4]), .b(s1_sum2[3]), .cin(s2_c3), .sum(s2_sum[5]), .cout(s2_c5));
    full_adder fa7(.a(s1_sum1[5]), .b(s1_sum2[4]), .cin(s2_c4), .sum(s2_sum[6]), .cout(s2_c6));
    
    // 最终结果计算
    assign dadda_product[0] = s2_sum[0];
    assign dadda_product[1] = s2_sum[1];
    assign dadda_product[2] = s2_sum[2];
    assign dadda_product[3] = s2_sum[3];
    assign dadda_product[4] = s2_sum[4];
    assign dadda_product[5] = s2_sum[5];
    assign dadda_product[6] = s2_sum[6];
    assign dadda_product[7] = s2_c6 | pp3[3];
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            grant <= 4'b0000;
            busy <= 1'b0;
            product <= 8'b00000000;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    grant <= 4'b0000;
                    busy <= 1'b0;
                    product <= dadda_product; // 在IDLE状态更新乘法结果
                end
                GRANT0: begin
                    grant <= 4'b0001;
                    busy <= 1'b1;
                    product <= dadda_product;
                end
                GRANT1: begin
                    grant <= 4'b0010;
                    busy <= 1'b1;
                    product <= dadda_product;
                end
                GRANT2: begin
                    grant <= 4'b0100;
                    busy <= 1'b1;
                    product <= dadda_product;
                end
                default: begin
                    grant <= 4'b1000;
                    busy <= 1'b1;
                    product <= dadda_product;
                end
            endcase
        end
    end
    
    always @(*) begin
        if (requests == 4'b0000)
            next_state = IDLE;
        else if (requests[0])
            next_state = GRANT0;
        else if (requests[1])
            next_state = GRANT1;
        else if (requests[2])
            next_state = GRANT2;
        else
            next_state = 2'b11; // GRANT3
    end
endmodule

// 半加器模块定义
module half_adder(
    input wire a,
    input wire b,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// 全加器模块定义
module full_adder(
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule