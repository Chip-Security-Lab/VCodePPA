//SystemVerilog
module Parity_XNOR (
    input  wire       clk,      // 时钟信号
    input  wire       rst_n,    // 复位信号，低电平有效
    input  wire [7:0] data,     // 输入数据
    output reg        parity    // 奇偶校验输出
);

    // 阶段1: 将8位数据分为4组，每组2位
    wire [1:0] data_group[3:0];
    assign data_group[0] = data[1:0];
    assign data_group[1] = data[3:2];
    assign data_group[2] = data[5:4];
    assign data_group[3] = data[7:6];

    // 阶段1: 初级奇偶校验计算
    reg [3:0] stage1_parity;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_parity <= 4'b0;
        end else begin
            stage1_parity[0] <= data_group[0][0] ^ data_group[0][1];
            stage1_parity[1] <= data_group[1][0] ^ data_group[1][1];
            stage1_parity[2] <= data_group[2][0] ^ data_group[2][1];
            stage1_parity[3] <= data_group[3][0] ^ data_group[3][1];
        end
    end

    // 阶段2: 中级奇偶校验计算
    reg [1:0] stage2_parity;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_parity <= 2'b0;
        end else begin
            stage2_parity[0] <= stage1_parity[0] ^ stage1_parity[1];
            stage2_parity[1] <= stage1_parity[2] ^ stage1_parity[3];
        end
    end

    // 阶段3: 最终奇偶校验计算 (XNOR操作)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity <= 1'b0;
        end else begin
            parity <= ~(stage2_parity[0] ^ stage2_parity[1]);
        end
    end

endmodule