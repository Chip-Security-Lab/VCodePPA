//SystemVerilog
module crc_dual_clock (
    input clk_a, clk_b, rst,
    input [7:0] data_a,
    output reg [15:0] crc_b
);
    reg [7:0] data_sync;
    reg [15:0] crc_reg;
    reg [15:0] crc_next;

    always @(posedge clk_a) begin  // 输入域
        // 此处添加跨时钟域同步逻辑
        data_sync <= data_a;
    end

    // 计算crc_next的组合逻辑
    always @(*) begin
        crc_next = {crc_reg[14:0], 1'b0} ^ {8'h00, data_sync};
        if (crc_reg[15]) begin
            crc_next = crc_next ^ 16'h8005;
        end
    end

    always @(posedge clk_b) begin  // 计算域
        if (rst) begin
            crc_reg <= 16'hFFFF;
        end
        else begin
            crc_reg <= crc_next;
        end
        crc_b <= crc_reg;
    end
endmodule