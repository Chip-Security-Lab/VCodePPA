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

    // 使用非阻塞赋值优化扫描链移位寄存器
    always @(posedge scan_clk) begin
        if (scan_en) begin
            scan_reg <= {scan_reg[SCAN_CHAIN-2:0], scan_in};
        end
    end

    // 优化I/O控制逻辑，使用case语句提高清晰度和综合效率
    always @(posedge clk) begin
        case (scan_en)
            1'b1: begin
                sda_out <= scan_reg[0];
                scl_out <= scan_reg[1];
                sda_oe <= 1'b1;
                scl_oe <= 1'b1;
            end
            1'b0: begin
                // 保持输出值但禁用输出使能
                sda_oe <= 1'b0;
                scl_oe <= 1'b0;
            end
        endcase
    end
    
    // I2C总线驱动优化 - 使用三目运算符提高综合效率
    assign scan_out = scan_reg[SCAN_CHAIN-1];
    assign sda = (sda_oe) ? sda_out : 1'bz;
    assign scl = (scl_oe) ? scl_out : 1'bz;
endmodule