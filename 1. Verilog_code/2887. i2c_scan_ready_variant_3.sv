//SystemVerilog
//IEEE 1364-2005 Verilog标准
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
    // 扫描链寄存器
    reg [SCAN_CHAIN-1:0] scan_reg;
    
    // 使用专用缓冲结构减少扇出负载，并分段优化
    (* keep = "true" *) reg [SCAN_CHAIN/2-1:0] scan_reg_buf1_low;
    (* keep = "true" *) reg [SCAN_CHAIN/2-1:0] scan_reg_buf1_high;
    (* keep = "true" *) reg [1:0] scan_reg_buf2_control;
    
    // I2C控制信号
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // 优化的扫描寄存器逻辑 - 使用条件移位
    always @(posedge scan_clk) begin
        if (scan_en) begin
            scan_reg <= {scan_reg[SCAN_CHAIN-2:0], scan_in};
        end
    end
    
    // 分段缓冲以减少关键路径负载，使用并行结构
    always @(posedge clk) begin
        scan_reg_buf1_low <= scan_reg[SCAN_CHAIN/2-1:0];
        scan_reg_buf1_high <= scan_reg[SCAN_CHAIN-1:SCAN_CHAIN/2];
        scan_reg_buf2_control <= {scan_reg[1], scan_reg[0]};
    end
    
    // 使用高段部分的最高位作为扫描输出
    assign scan_out = scan_reg_buf1_high[SCAN_CHAIN/2-1];
    
    // 使用专用控制缓冲，提高I2C控制时序可靠性 - 扁平化if-else结构
    always @(posedge clk) begin
        if (scan_en) begin
            sda_out <= scan_reg_buf2_control[0];
            scl_out <= scan_reg_buf2_control[1];
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
        end
        
        if (!scan_en) begin
            // 默认三态，维持总线空闲
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
        end
    end
    
    // I2C总线三态控制 - 优化结构减少延迟
    assign sda = (sda_oe) ? sda_out : 1'bz;
    assign scl = (scl_oe) ? scl_out : 1'bz;
endmodule