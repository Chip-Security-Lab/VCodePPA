//SystemVerilog
module SecurityBridge #(
    parameter ADDR_MASK = 32'hFFFF_0000
)(
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,
    input wire [1:0] priv_level,
    output reg access_grant
);
    // 地址解码和权限检查分段处理
    reg [31:0] masked_addr;
    reg [1:0] priv_level_reg;
    reg addr_in_secure_region;
    reg addr_in_privileged_region;
    reg required_priv_level_met;
    
    // 第一级流水线：地址掩码和输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_addr <= 32'h0;
            priv_level_reg <= 2'b00;
        end else begin
            masked_addr <= addr & ADDR_MASK;
            priv_level_reg <= priv_level;
        end
    end
    
    // 第二级流水线：地址解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_in_secure_region <= 1'b0;
            addr_in_privileged_region <= 1'b0;
        end else begin
            addr_in_secure_region <= (masked_addr == 32'h4000_0000);
            addr_in_privileged_region <= (masked_addr == 32'h2000_0000);
        end
    end
    
    // 第三级流水线：权限检查
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            required_priv_level_met <= 1'b0;
        end else begin
            required_priv_level_met <= (addr_in_secure_region && (priv_level_reg >= 2'b10)) || 
                                       (addr_in_privileged_region && (priv_level_reg >= 2'b01)) ||
                                       (!addr_in_secure_region && !addr_in_privileged_region);
        end
    end
    
    // 第四级流水线：访问权限授予
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_grant <= 1'b0;
        end else begin
            access_grant <= required_priv_level_met;
        end
    end
endmodule