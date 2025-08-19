//SystemVerilog
module parity_generator #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             data_valid,
    input  wire [WIDTH-1:0] data_i,
    input  wire             odd_parity,
    output reg              parity_bit,
    output reg              parity_valid
);

    // 第一级流水线 - 分割数据
    reg [WIDTH/4-1:0] data_0_r, data_1_r, data_2_r, data_3_r;
    reg odd_parity_r;
    reg data_valid_r;
    wire partial_parity_0, partial_parity_1, partial_parity_2, partial_parity_3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_0_r <= {(WIDTH/4){1'b0}};
            data_1_r <= {(WIDTH/4){1'b0}};
            data_2_r <= {(WIDTH/4){1'b0}};
            data_3_r <= {(WIDTH/4){1'b0}};
            odd_parity_r <= 1'b0;
            data_valid_r <= 1'b0;
        end else begin
            data_0_r <= data_i[WIDTH/4-1:0];
            data_1_r <= data_i[WIDTH/2-1:WIDTH/4];
            data_2_r <= data_i[3*WIDTH/4-1:WIDTH/2];
            data_3_r <= data_i[WIDTH-1:3*WIDTH/4];
            odd_parity_r <= odd_parity;
            data_valid_r <= data_valid;
        end
    end
    
    // 计算部分校验位
    assign partial_parity_0 = ^data_0_r;
    assign partial_parity_1 = ^data_1_r;
    assign partial_parity_2 = ^data_2_r;
    assign partial_parity_3 = ^data_3_r;
    
    // 第二级流水线 - 合并部分校验位和计算中间校验位
    reg partial_parity_0_r, partial_parity_1_r;
    reg partial_parity_2_r, partial_parity_3_r;
    reg odd_parity_r2;
    reg data_valid_r2;
    reg partial_parity_low_r, partial_parity_high_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_parity_0_r <= 1'b0;
            partial_parity_1_r <= 1'b0;
            partial_parity_2_r <= 1'b0;
            partial_parity_3_r <= 1'b0;
            odd_parity_r2 <= 1'b0;
            data_valid_r2 <= 1'b0;
            partial_parity_low_r <= 1'b0;
            partial_parity_high_r <= 1'b0;
        end else begin
            partial_parity_0_r <= partial_parity_0;
            partial_parity_1_r <= partial_parity_1;
            partial_parity_2_r <= partial_parity_2;
            partial_parity_3_r <= partial_parity_3;
            odd_parity_r2 <= odd_parity_r;
            data_valid_r2 <= data_valid_r;
            // 前移第三级流水线的逻辑到第二级
            partial_parity_low_r <= partial_parity_0 ^ partial_parity_1;
            partial_parity_high_r <= partial_parity_2 ^ partial_parity_3;
        end
    end
    
    // 第三级流水线 - 合并中间校验位，计算最终校验位结果
    reg odd_parity_r3;
    reg data_valid_r3;
    reg even_parity_result_r;
    reg final_parity_bit_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            odd_parity_r3 <= 1'b0;
            data_valid_r3 <= 1'b0;
            even_parity_result_r <= 1'b0;
            final_parity_bit_r <= 1'b0;
        end else begin
            odd_parity_r3 <= odd_parity_r2;
            data_valid_r3 <= data_valid_r2;
            // 计算最终偶校验结果并前移第四级部分逻辑到这里
            even_parity_result_r <= partial_parity_low_r ^ partial_parity_high_r;
            final_parity_bit_r <= (partial_parity_low_r ^ partial_parity_high_r) ^ odd_parity_r2;
        end
    end
    
    // 第四级流水线 - 输出最终校验位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_bit <= 1'b0;
            parity_valid <= 1'b0;
        end else begin
            parity_bit <= final_parity_bit_r;
            parity_valid <= data_valid_r3;
        end
    end
endmodule