//SystemVerilog
module cdc_clock_gate (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire src_en,
    input  wire rst_n,
    output wire gated_dst_clk
);
    reg src_en_reg;
    reg meta, sync;
    
    // 在源时钟域添加寄存器以捕获源使能信号
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            src_en_reg <= 1'b0;
        end else begin
            src_en_reg <= src_en;
        end
    end
    
    // 同步逻辑使用预先寄存的源使能信号
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            meta <= 1'b0;
            sync <= 1'b0;
        end else begin
            meta <= src_en_reg;
            sync <= meta;
        end
    end
    
    // 使用AND门实现门控时钟
    assign gated_dst_clk = dst_clk & sync;
endmodule