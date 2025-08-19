//SystemVerilog
module auto_poly_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] data_len,
    output reg [15:0] crc_out
);
    reg [15:0] polynomial;
    wire [15:0] booth_mult_result;
    reg [15:0] mult_operand_a;
    reg [15:0] mult_operand_b;
    reg use_mult;
    
    // 选择多项式
    always @(*) begin
        case (data_len)
            8'd8:    polynomial = 16'h0007; // 8-bit CRC
            8'd16:   polynomial = 16'h8005; // 16-bit CRC
            default: polynomial = 16'h1021; // CCITT
        endcase
    end
    
    // 准备乘法器操作数
    always @(*) begin
        if (crc_out[15] ^ data[0]) begin
            mult_operand_a = {crc_out[14:0], 1'b0};
            mult_operand_b = polynomial;
            use_mult = 1'b1;
        end else begin
            mult_operand_a = 16'h0000;
            mult_operand_b = 16'h0000;
            use_mult = 1'b0;
        end
    end
    
    // CRC计算逻辑
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 16'h0000;
        end else begin
            if (use_mult) begin
                crc_out <= {crc_out[14:0], 1'b0} ^ booth_mult_result;
            end else begin
                crc_out <= {crc_out[14:0], 1'b0};
            end
        end
    end
    
    // 实例化Booth乘法器
    booth_multiplier_16bit booth_mult (
        .clk(clk),
        .rst(rst),
        .multiplicand(mult_operand_a),
        .multiplier(mult_operand_b),
        .product(booth_mult_result)
    );
endmodule

// Booth乘法器实现 (16位)
module booth_multiplier_16bit(
    input wire clk,
    input wire rst,
    input wire [15:0] multiplicand,
    input wire [15:0] multiplier,
    output reg [15:0] product
);
    reg [32:0] A_Q_Q_1;  // A拼接Q拼接Q_1
    reg [15:0] M;        // 被乘数
    reg [4:0] count;     // 迭代计数器

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A_Q_Q_1 <= 33'b0;
            M <= 16'b0;
            count <= 5'b0;
            product <= 16'b0;
        end else begin
            // 初始化
            if (count == 0) begin
                A_Q_Q_1 <= {16'b0, multiplier, 1'b0};
                M <= multiplicand;
                count <= count + 1'b1;
            end
            // Booth算法迭代
            else if (count <= 16) begin
                case (A_Q_Q_1[1:0])
                    2'b01: A_Q_Q_1[32:17] <= A_Q_Q_1[32:17] + M;                 // +M
                    2'b10: A_Q_Q_1[32:17] <= A_Q_Q_1[32:17] + (~M + 1'b1);       // -M
                    default: ;  // 2'b00或2'b11不做操作
                endcase
                
                // 算术右移
                A_Q_Q_1 <= {{A_Q_Q_1[32]}, A_Q_Q_1[32:1]};
                count <= count + 1'b1;
                
                // 完成最后一次迭代后更新输出
                if (count == 16) begin
                    product <= A_Q_Q_1[16:1];  // 取结果的低16位
                    count <= 5'b0;             // 重置计数器准备下一次乘法
                end
            end
        end
    end
endmodule