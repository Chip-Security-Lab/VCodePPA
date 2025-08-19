module param_adder #(parameter WIDTH=4) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH:0] sum
);

    // 输入寄存器级
    reg [WIDTH-1:0] a_reg;
    reg [WIDTH-1:0] b_reg;

    // 中间计算级
    wire [WIDTH:0] sum_next;

    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 组合逻辑计算 - 使用进位保存加法器结构
    wire [WIDTH:0] carry;
    wire [WIDTH:0] sum_temp;
    
    assign carry[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_chain
            assign sum_temp[i] = a_reg[i] ^ b_reg[i] ^ carry[i];
            assign carry[i+1] = (a_reg[i] & b_reg[i]) | (carry[i] & (a_reg[i] ^ b_reg[i]));
        end
    endgenerate
    assign sum_temp[WIDTH] = carry[WIDTH];
    assign sum_next = sum_temp;

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= {(WIDTH+1){1'b0}};
        end else begin
            sum <= sum_next;
        end
    end

endmodule