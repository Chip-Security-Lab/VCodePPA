//SystemVerilog
module shadow_reg_parity #(parameter DW=8) (
    input clk, rstn, en,
    input [DW-1:0] din,
    output reg [DW:0] dout  // [DW]位为校验位
);
    // 计算偶校验位的优化实现
    reg parity_reg;
    reg parity_reg_pipeline; // 流水线寄存器

    // 使用组合逻辑提前计算校验位，减少关键路径
    always @(*) begin
        parity_reg = ^din;
    end

    // 插入流水线寄存器以减少组合逻辑延迟
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            parity_reg_pipeline <= 1'b0; // 初始化流水线寄存器
        end else begin
            if (en) begin
                parity_reg_pipeline <= parity_reg; // 更新流水线寄存器
            end
        end
    end

    // 使用非阻塞赋值并分离复位逻辑以改善时序性能
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= {(DW+1){1'b0}};  // 参数化的复位宽度，提高可配置性
        end else begin
            if (en) begin
                dout <= {parity_reg_pipeline, din};  // 使用寄存的校验位减少扇出
            end
        end
    end
endmodule