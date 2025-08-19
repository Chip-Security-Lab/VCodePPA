//SystemVerilog
module crc8_generator #(
    parameter POLY = 8'h07  // CRC-8多项式 x^8 + x^2 + x + 1
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire data_in,
    input wire init,  // 初始化信号
    output wire [7:0] crc_out
);

    // 流水线级别1: 输入寄存器和valid信号
    reg data_in_stage1;
    reg enable_stage1;
    reg init_stage1;
    reg valid_stage1;

    // 流水线级别2: feedback计算和valid信号
    reg feedback_stage2;
    reg [7:0] crc_reg_stage2;
    reg enable_stage2;
    reg init_stage2;
    reg valid_stage2;

    // 流水线级别3: next_crc计算和寄存器
    reg [7:0] next_crc_stage3;
    reg init_stage3;
    reg enable_stage3;
    reg valid_stage3;

    // CRC主寄存器
    reg [7:0] crc_reg_stage3;

    // 输入寄存器级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1   <= 1'b0;
            enable_stage1    <= 1'b0;
            init_stage1      <= 1'b0;
            valid_stage1     <= 1'b0;
        end else begin
            data_in_stage1   <= data_in;
            enable_stage1    <= enable;
            init_stage1      <= init;
            valid_stage1     <= enable | init;
        end
    end

    // feedback计算级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_stage2    <= 1'b0;
            crc_reg_stage2     <= 8'h00;
            enable_stage2      <= 1'b0;
            init_stage2        <= 1'b0;
            valid_stage2       <= 1'b0;
        end else begin
            feedback_stage2    <= crc_reg_stage3[7] ^ data_in_stage1;
            crc_reg_stage2     <= crc_reg_stage3;
            enable_stage2      <= enable_stage1;
            init_stage2        <= init_stage1;
            valid_stage2       <= valid_stage1;
        end
    end

    // next_crc计算级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_crc_stage3 <= 8'h00;
            enable_stage3   <= 1'b0;
            init_stage3     <= 1'b0;
            valid_stage3    <= 1'b0;
        end else begin
            if (enable_stage2) begin
                if (feedback_stage2)
                    next_crc_stage3 <= {crc_reg_stage2[6:0], 1'b0} ^ POLY;
                else
                    next_crc_stage3 <= {crc_reg_stage2[6:0], 1'b0};
            end else begin
                next_crc_stage3 <= crc_reg_stage2;
            end
            enable_stage3   <= enable_stage2;
            init_stage3     <= init_stage2;
            valid_stage3    <= valid_stage2;
        end
    end

    // CRC主寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg_stage3 <= 8'h00;
        end else if (init_stage3) begin
            crc_reg_stage3 <= 8'h00;
        end else if (enable_stage3) begin
            crc_reg_stage3 <= next_crc_stage3;
        end
    end

    assign crc_out = crc_reg_stage3;

endmodule