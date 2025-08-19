//SystemVerilog
// 顶层模块：AXI奇偶校验检查器
module axi_parity_checker (
    input  wire        aclk,    // 时钟信号
    input  wire        arstn,   // 复位信号，低电平有效
    input  wire [31:0] tdata,   // 输入数据
    input  wire        tvalid,  // 数据有效标志
    output wire        tparity  // 奇偶校验结果
);
    // 内部连接信号
    wire parity_bit;
    
    // 实例化数据奇偶校验计算子模块
    parity_calculator u_parity_calc (
        .data_in  (tdata),
        .parity   (parity_bit)
    );
    
    // 实例化寄存器控制子模块
    parity_register u_parity_reg (
        .aclk     (aclk),
        .arstn    (arstn),
        .valid    (tvalid),
        .parity_in(parity_bit),
        .parity_out(tparity)
    );
    
endmodule

// 子模块1：奇偶校验计算模块
module parity_calculator #(
    parameter DATA_WIDTH = 32  // 参数化数据宽度，提高可复用性
) (
    input  wire [DATA_WIDTH-1:0] data_in,  // 输入数据
    output wire                  parity     // 计算得到的奇偶校验位
);
    // 组合逻辑计算奇偶校验
    assign parity = ^data_in;
    
endmodule

// 子模块2：奇偶校验寄存器控制模块
module parity_register (
    input  wire  aclk,       // 时钟信号
    input  wire  arstn,      // 复位信号，低电平有效
    input  wire  valid,      // 数据有效标志
    input  wire  parity_in,  // 输入的奇偶校验位
    output reg   parity_out  // 寄存器输出的奇偶校验位
);
    // 时序逻辑，带使能的奇偶校验寄存器
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) 
            parity_out <= 1'b0;
        else if (valid) 
            parity_out <= parity_in;
    end
    
endmodule