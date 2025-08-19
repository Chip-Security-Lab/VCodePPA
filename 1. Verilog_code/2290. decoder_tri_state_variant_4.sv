//SystemVerilog
module decoder_tri_state (
    input wire clk,          // 新增时钟信号，用于流水线寄存器
    input wire rst_n,        // 新增复位信号，用于同步复位
    input wire oe,           // 输出使能
    input wire [2:0] addr,   // 3位地址输入
    output reg [7:0] bus     // 8位总线输出
);
    // 阶段1：地址解码阶段
    reg [2:0] addr_stage1;
    reg oe_stage1;
    
    // 阶段2：总线驱动阶段
    reg [7:0] decoded_value;
    
    // 第一阶段流水线：捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 3'b000;
            oe_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            oe_stage1 <= oe;
        end
    end
    
    // 第二阶段流水线：解码地址
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_value <= 8'h00;
        end else begin
            decoded_value <= (8'h01 << addr_stage1);
        end
    end
    
    // 输出驱动：基于输出使能和解码值
    always @(*) begin
        bus = oe_stage1 ? decoded_value : 8'hZZ;
    end
    
endmodule