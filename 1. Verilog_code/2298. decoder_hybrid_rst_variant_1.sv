//SystemVerilog
module decoder_hybrid_rst #(parameter SYNC_RST=1) (
    input clk, async_rst, sync_rst,
    input [3:0] addr,
    output reg [15:0] decoded
);
    // 将组合逻辑从时序逻辑中分离
    reg [3:0] addr_reg;
    wire [15:0] decoded_comb;
    
    // 使用中间变量简化复位逻辑判断
    wire sync_rst_active;
    wire reset_active;
    
    // 分解复杂条件表达式为多级简单条件
    assign sync_rst_active = SYNC_RST && sync_rst;
    assign reset_active = async_rst || sync_rst_active;
    
    // 简化的地址寄存逻辑，使用多级条件
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            addr_reg <= 4'b0;
        end
        else begin
            if (sync_rst_active) begin
                addr_reg <= 4'b0;
            end
            else begin
                addr_reg <= addr;
            end
        end
    end
    
    // 使用参数化方法生成解码输出
    // 简化表达式，提高可读性
    wire [15:0] one_hot;
    assign one_hot = 16'h0001;
    assign decoded_comb = one_hot << addr_reg;
    
    // 优化的输出寄存器逻辑，使用简化的多级条件
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            decoded <= 16'b0;
        end
        else begin
            if (sync_rst_active) begin
                decoded <= 16'b0;
            end
            else begin
                decoded <= decoded_comb;
            end
        end
    end
endmodule