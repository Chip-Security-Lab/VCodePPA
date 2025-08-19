//SystemVerilog
module mul_add (
    input clk,
    input rst_n,
    input [3:0] num1,
    input [3:0] num2,
    input valid_in,
    output reg ready_in,
    output reg [7:0] product,
    output reg [4:0] sum,
    output reg valid_out,
    input ready_out
);
    reg [3:0] num1_reg, num2_reg;
    reg data_valid;
    reg [7:0] product_next;
    reg [4:0] sum_next;
    
    // 输入握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num1_reg <= 4'b0;
            num2_reg <= 4'b0;
            data_valid <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            if (valid_in && ready_in) begin
                num1_reg <= num1;
                num2_reg <= num2;
                data_valid <= 1'b1;
                ready_in <= 1'b0; // 接收数据后暂时不接收新数据
            end else if (valid_out && ready_out) begin
                data_valid <= 1'b0;
                ready_in <= 1'b1; // 输出数据被接收后，准备接收新数据
            end
        end
    end
    
    // 计算逻辑
    always @(*) begin
        product_next = num1_reg * num2_reg;
        sum_next = num1_reg + num2_reg;
    end
    
    // 输出握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'b0;
            sum <= 5'b0;
            valid_out <= 1'b0;
        end else begin
            if (data_valid && !valid_out) begin
                // 新数据计算完成且输出通道空闲
                product <= product_next;
                sum <= sum_next;
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                // 数据被下游模块接收
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule