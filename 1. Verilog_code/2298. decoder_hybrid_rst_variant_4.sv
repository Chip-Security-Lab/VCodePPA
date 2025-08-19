//SystemVerilog
//IEEE 1364-2005 Verilog
module decoder_hybrid_rst #(
    parameter SYNC_RST = 1
)(
    input  wire        clk,        // 系统时钟
    input  wire        async_rst,  // 异步复位信号
    input  wire        sync_rst,   // 同步复位信号
    input  wire [3:0]  addr,       // 地址输入
    output reg  [15:0] decoded     // 解码输出
);
    // 复位控制路径
    reg        reset_stage1;
    wire       effective_rst;
    
    // 解码数据路径
    reg  [3:0] addr_registered;
    wire [15:0] decoded_vector;
    reg  [15:0] decoded_next;
    
    // 第一级：复位信号处理
    assign effective_rst = async_rst || (SYNC_RST && sync_rst);
    
    // 第二级：地址寄存及复位信号同步
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            addr_registered <= 4'h0;
            reset_stage1 <= 1'b1;
        end
        else begin
            addr_registered <= addr;
            reset_stage1 <= effective_rst;
        end
    end
    
    // 第三级：解码逻辑 - 拆分为基础解码和复位控制
    assign decoded_vector = (1'b1 << addr_registered);
    
    always @(*) begin
        if (reset_stage1) begin
            decoded_next = 16'h0000;
        end
        else begin
            decoded_next = decoded_vector;
        end
    end
    
    // 第四级：输出寄存器
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            decoded <= 16'h0000;
        end
        else begin
            decoded <= decoded_next;
        end
    end
    
endmodule