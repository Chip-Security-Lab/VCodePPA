//SystemVerilog
module EnabledNOT(
    input wire clk,        // 添加时钟信号用于流水线寄存器
    input wire rst_n,      // 添加复位信号
    input wire en,
    input wire [3:0] src,
    output wire [3:0] result
);
    // 内部信号定义 - 重新组织数据流路径
    wire [3:0] inverted_data_stage1;
    reg  [3:0] inverted_data_reg;  // 流水线寄存器
    reg  en_reg;                   // 流水线使能寄存器
    
    // 第一阶段 - 数据反转
    NOT_Core #(.DATA_WIDTH(4)) not_logic_inst (
        .src(src),
        .inverted_data(inverted_data_stage1)
    );
    
    // 流水线寄存器 - 分割数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_data_reg <= 4'b0;
            en_reg <= 1'b0;
        end else begin
            inverted_data_reg <= inverted_data_stage1;
            en_reg <= en;
        end
    end
    
    // 第二阶段 - 输出控制
    OutputControl #(.DATA_WIDTH(4)) output_ctrl_inst (
        .en(en_reg),
        .data_in(inverted_data_reg),
        .result(result)
    );
    
endmodule

// 优化的NOT逻辑核心子模块
module NOT_Core #(
    parameter DATA_WIDTH = 4
)(
    input wire [DATA_WIDTH-1:0] src,
    output wire [DATA_WIDTH-1:0] inverted_data
);
    // 并行优化实现，减少逻辑深度
    assign inverted_data = ~src;
endmodule

// 优化的输出控制子模块
module OutputControl #(
    parameter DATA_WIDTH = 4
)(
    input wire en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] result
);
    // 使用寄存器输出，提高驱动能力并改善时序
    always @(*) begin
        result = en ? data_in : {DATA_WIDTH{1'bz}};
    end
endmodule