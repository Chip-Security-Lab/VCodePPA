module unsigned_subtractor_4bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  a,
    input  wire [3:0]  b,
    output reg  [3:0]  diff
);

    // 内部寄存器
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [3:0] diff_next;
    reg [3:0] sum_reg;
    reg [3:0] carry_reg;
    reg [3:0] temp_sum;
    reg [3:0] temp_carry;

    // 第一级流水线：输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 第二级流水线：条件求和减法计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 4'b0;
            carry_reg <= 4'b0;
        end else begin
            // 计算每一位的条件和
            temp_sum[0] = a_reg[0] ^ ~b_reg[0];
            temp_carry[0] = a_reg[0] & ~b_reg[0];
            
            temp_sum[1] = a_reg[1] ^ ~b_reg[1] ^ temp_carry[0];
            temp_carry[1] = (a_reg[1] & ~b_reg[1]) | (temp_carry[0] & (a_reg[1] ^ ~b_reg[1]));
            
            temp_sum[2] = a_reg[2] ^ ~b_reg[2] ^ temp_carry[1];
            temp_carry[2] = (a_reg[2] & ~b_reg[2]) | (temp_carry[1] & (a_reg[2] ^ ~b_reg[2]));
            
            temp_sum[3] = a_reg[3] ^ ~b_reg[3] ^ temp_carry[2];
            temp_carry[3] = (a_reg[3] & ~b_reg[3]) | (temp_carry[2] & (a_reg[3] ^ ~b_reg[3]));
            
            sum_reg <= temp_sum;
            carry_reg <= temp_carry;
        end
    end

    // 第三级流水线：输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
        end else begin
            diff <= sum_reg;
        end
    end

endmodule