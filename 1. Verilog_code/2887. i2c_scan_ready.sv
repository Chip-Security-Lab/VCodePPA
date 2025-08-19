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

    always @(posedge scan_clk) begin
        if (scan_en) begin
            scan_reg <= {scan_reg[SCAN_CHAIN-2:0], scan_in};
        end
    end

    assign scan_out = scan_reg[SCAN_CHAIN-1];

    // 边界扫描控制
    always @(posedge clk) begin
        if (scan_en) begin
            sda_out <= scan_reg[0];
            scl_out <= scan_reg[1];
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
        end else begin
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
        end
    end
    
    // I2C总线驱动
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
endmodule