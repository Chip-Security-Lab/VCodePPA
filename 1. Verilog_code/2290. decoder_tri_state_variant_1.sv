//SystemVerilog
module decoder_tri_state (
    input wire        clk,       // 系统时钟
    input wire        rst_n,     // 异步复位，低有效
    input wire        oe,        // 输出使能信号
    input wire [2:0]  addr,      // 地址输入
    output reg [7:0]  bus        // 总线输出
);

    // 内部信号定义
    reg [2:0] addr_r;            // 地址寄存器
    reg       oe_r;              // 输出使能寄存器
    reg [7:0] decoder_out;       // 解码器输出寄存

    // 简化流水线结构，减少无用寄存器
    // 第一级流水：捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_r <= 3'b000;
            oe_r   <= 1'b0;
        end else begin
            addr_r <= addr;
            oe_r   <= oe;
        end
    end

    // 第二级流水：执行解码操作并直接输出到总线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoder_out <= 8'h00;
        end else begin
            decoder_out <= 8'h01 << addr_r;
        end
    end

    // 第三级流水：处理输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus <= 8'hZZ;
        end else if (oe_r) begin
            bus <= decoder_out;
        end else begin
            bus <= 8'hZZ;
        end
    end

endmodule