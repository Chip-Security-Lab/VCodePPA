//SystemVerilog
module multiplier_4bit (
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    input req,
    output reg ack,
    output reg [7:0] product
);

    reg [7:0] product_reg;
    reg req_prev;
    reg [3:0] a_abs;
    reg [3:0] b_abs;
    reg sign;
    reg [7:0] partial_prod;
    reg [2:0] count;
    reg [7:0] accum;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 8'b0;
            ack <= 1'b0;
            req_prev <= 1'b0;
            a_abs <= 4'b0;
            b_abs <= 4'b0;
            sign <= 1'b0;
            partial_prod <= 8'b0;
            count <= 3'b0;
            accum <= 8'b0;
        end else begin
            req_prev <= req;
            
            if (req && !req_prev) begin
                // 计算符号位
                sign <= a[3] ^ b[3];
                
                // 取绝对值
                a_abs <= a[3] ? (~a + 1'b1) : a;
                b_abs <= b[3] ? (~b + 1'b1) : b;
                
                // 初始化累加器和计数器
                accum <= 8'b0;
                count <= 3'b0;
                ack <= 1'b0;
            end else if (count < 3'd4) begin
                // 移位累加乘法
                if (b_abs[count]) begin
                    accum <= accum + (a_abs << count);
                end
                count <= count + 1'b1;
                
                if (count == 3'd3) begin
                    // 根据符号位调整结果
                    product_reg <= sign ? (~accum + 1'b1) : accum;
                    ack <= 1'b1;
                end
            end else if (!req) begin
                ack <= 1'b0;
            end
        end
    end
    
    assign product = product_reg;
    
endmodule