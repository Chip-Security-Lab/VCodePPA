//SystemVerilog
module ProgIntervalTimer (
    input clk, rst_n, load,
    input [15:0] threshold,
    output reg intr
);
    reg [15:0] cnt;
    reg cnt_is_one;
    
    // 查找表实现减法
    reg [3:0] lut_sub_result [0:15][0:15];
    reg [4:0] i, j;
    reg carry;
    reg [15:0] next_cnt;
    
    // 初始化查找表
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                lut_sub_result[i][j] = i - j;
            end
        end
    end
    
    // 查找表辅助减法运算
    always @(*) begin
        carry = 0;
        for (i = 0; i < 4; i = i + 1) begin
            // 4位一组进行查表减法
            {carry, next_cnt[i*4+:4]} = {1'b0, lut_sub_result[cnt[i*4+:4]][{3'b000, carry}]} - {4'b0000, (i == 0) ? 1'b1 : 1'b0};
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 16'd0;
            cnt_is_one <= 1'b0;
            intr <= 1'b0;
        end
        else if (load) begin
            cnt <= threshold;
            cnt_is_one <= (threshold == 16'd1);
            intr <= cnt_is_one;
        end
        else begin
            cnt <= (cnt == 16'd0) ? 16'd0 : next_cnt;
            cnt_is_one <= (cnt == 16'd2);
            intr <= cnt_is_one;
        end
    end
endmodule