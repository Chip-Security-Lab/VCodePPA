//SystemVerilog
module i2c_scan_ready #(
    parameter SCAN_CHAIN = 32
)(
    input clk,
    input scan_clk,
    input scan_en,
    input scan_in,
    output scan_out,
    inout sda,
    inout scl
);
    // 扫描链插入
    reg [SCAN_CHAIN-1:0] scan_reg;
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // 补码加法实现减法
    reg [7:0] minuend, subtrahend;
    reg [7:0] difference;
    reg [7:0] negated_subtrahend;
    reg carry;
    
    // 扫描链处理
    always @(posedge scan_clk) begin
        if (scan_en) begin
            scan_reg <= {scan_reg[SCAN_CHAIN-2:0], scan_in};
        end
    end

    assign scan_out = scan_reg[SCAN_CHAIN-1];

    // 使用补码加法实现减法运算
    always @(posedge clk) begin
        if (scan_en) begin
            // 提取减法数据
            minuend <= scan_reg[15:8];
            subtrahend <= scan_reg[7:0];
            
            // 对减数取反加一（生成补码）
            negated_subtrahend <= ~subtrahend + 8'b1;
            
            // 直接使用加法执行减法（A-B = A+(-B)）
            {carry, difference} <= {1'b0, minuend} + {1'b0, negated_subtrahend};
            
            // 边界扫描控制
            sda_out <= scan_reg[0];
            scl_out <= scan_reg[1];
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
        end else begin
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
        end
    end
    
    // I2C总线驱动 - 使用改进的三态逻辑
    assign sda = sda_oe ? (difference[0] ? sda_out : 1'b0) : 1'bz;
    assign scl = scl_oe ? (carry ? scl_out : 1'b0) : 1'bz;
endmodule