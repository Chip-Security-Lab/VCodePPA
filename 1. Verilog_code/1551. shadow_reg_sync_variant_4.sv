//SystemVerilog
module shadow_reg_sync #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  rst_n,
    input                  en,
    input  [WIDTH-1:0]     data_in,
    output reg [WIDTH-1:0] data_out
);

    // 分段数据通路：使用中间寄存器优化路径
    reg [WIDTH-1:0] shadow_reg;
    reg             transfer_pending;
    
    // 数据捕获阶段 - 管理shadow寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_reg <= {WIDTH{1'b0}};
            transfer_pending <= 1'b0;
        end
        else if (en) begin
            shadow_reg <= data_in;
            transfer_pending <= 1'b1;
        end
        else if (transfer_pending) begin
            transfer_pending <= 1'b0;
        end
    end
    
    // 数据输出阶段 - 管理最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end
        else if (transfer_pending && !en) begin
            data_out <= shadow_reg;
        end
    end

endmodule