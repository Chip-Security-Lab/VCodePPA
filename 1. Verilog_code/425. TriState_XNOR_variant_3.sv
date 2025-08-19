//SystemVerilog
//IEEE 1364-2005 Verilog标准
// Top module
module TriState_XNOR #(
    parameter DATA_WIDTH = 4,
    parameter PIPELINE_STAGES = 3  // 配置流水线级数
)(
    input                    clk,       // 时钟信号
    input                    rst_n,     // 复位信号
    input                    oe,        // 输出使能
    input                    valid_in,  // 输入数据有效
    output                   ready_out, // 可接收新数据
    input  [DATA_WIDTH-1:0]  in1, 
    input  [DATA_WIDTH-1:0]  in2,
    output [DATA_WIDTH-1:0]  res,
    output                   valid_out  // 输出数据有效
);
    // 流水线阶段间的数据和控制信号
    wire [DATA_WIDTH-1:0] xnor_result;
    wire valid_stage1, valid_stage2;
    wire [DATA_WIDTH-1:0] xnor_stage1, xnor_stage2;
    
    // 流水线控制逻辑
    assign ready_out = 1'b1; // 此设计始终准备好接收新数据
    
    // 实例化计算模块（带流水线）
    XNOR_Logic #(
        .DATA_WIDTH(DATA_WIDTH),
        .PIPELINE_STAGES(2)  // 使用两级流水线
    ) xnor_logic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .in1(in1),
        .in2(in2),
        .xnor_out(xnor_result),
        .valid_out(valid_stage2)
    );
    
    // 实例化输出缓冲模块（增加流水线）
    Tristate_Buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .PULL_TYPE("NONE"),
        .PIPELINE_EN(1)      // 启用流水线
    ) output_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .oe(oe),
        .valid_in(valid_stage2),
        .data_in(xnor_result),
        .data_out(res),
        .valid_out(valid_out)
    );
    
endmodule

// 流水线化XNOR计算模块
module XNOR_Logic #(
    parameter DATA_WIDTH = 4,
    parameter PIPELINE_STAGES = 2  // 配置流水线级数
)(
    input                    clk,       // 时钟输入
    input                    rst_n,     // 复位输入
    input                    valid_in,  // 输入数据有效
    input  [DATA_WIDTH-1:0]  in1, 
    input  [DATA_WIDTH-1:0]  in2,
    output [DATA_WIDTH-1:0]  xnor_out,
    output                   valid_out  // 输出数据有效
);
    // 流水线寄存器声明
    reg [DATA_WIDTH-1:0] stage1_xnor_reg, stage2_xnor_reg;
    reg stage1_valid_reg, stage2_valid_reg;
    
    // 第一级流水线：计算XNOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xnor_reg <= {DATA_WIDTH{1'b0}};
            stage1_valid_reg <= 1'b0;
        end else begin
            stage1_xnor_reg <= ~(in1 ^ in2);
            stage1_valid_reg <= valid_in;
        end
    end
    
    // 第二级流水线：传递结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xnor_reg <= {DATA_WIDTH{1'b0}};
            stage2_valid_reg <= 1'b0;
        end else begin
            stage2_xnor_reg <= stage1_xnor_reg;
            stage2_valid_reg <= stage1_valid_reg;
        end
    end
    
    // 最终输出
    assign xnor_out = stage2_xnor_reg;
    assign valid_out = stage2_valid_reg;
endmodule

// 增强的带流水线的三态缓冲模块
module Tristate_Buffer #(
    parameter DATA_WIDTH = 4,
    parameter PULL_TYPE = "NONE",  // 选项: "NONE", "UP", "DOWN"
    parameter PIPELINE_EN = 0      // 启用流水线
)(
    input                    clk,       // 时钟输入（流水线模式使用）
    input                    rst_n,     // 复位输入（流水线模式使用）
    input                    oe,
    input                    valid_in,  // 输入数据有效
    input  [DATA_WIDTH-1:0]  data_in,
    output [DATA_WIDTH-1:0]  data_out,
    output                   valid_out  // 输出数据有效
);
    genvar i;
    
    generate
        if (PIPELINE_EN) begin: PIPELINE_BUFFER
            // 流水线寄存器
            reg [DATA_WIDTH-1:0] data_reg;
            reg oe_reg;
            reg valid_reg;
            
            // 流水线寄存器逻辑
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    data_reg <= {DATA_WIDTH{1'b0}};
                    oe_reg <= 1'b0;
                    valid_reg <= 1'b0;
                end else begin
                    data_reg <= data_in;
                    oe_reg <= oe;
                    valid_reg <= valid_in;
                end
            end
            
            // 三态输出逻辑
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin : BUFFER_GEN
                case (PULL_TYPE)
                    "UP": begin : PULL_UP
                        assign data_out[i] = oe_reg ? data_reg[i] : 1'bz;
                    end
                    
                    "DOWN": begin : PULL_DOWN
                        assign data_out[i] = oe_reg ? data_reg[i] : 1'bz;
                    end
                    
                    default: begin : NO_PULL
                        assign data_out[i] = oe_reg ? data_reg[i] : 1'bz;
                    end
                endcase
            end
            
            // 输出有效信号
            assign valid_out = valid_reg;
            
        end else begin: COMB_BUFFER
            // 不使用流水线的原始三态缓冲逻辑
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin : BUFFER_GEN
                case (PULL_TYPE)
                    "UP": begin : PULL_UP
                        assign data_out[i] = oe ? data_in[i] : 1'bz;
                    end
                    
                    "DOWN": begin : PULL_DOWN
                        assign data_out[i] = oe ? data_in[i] : 1'bz;
                    end
                    
                    default: begin : NO_PULL
                        assign data_out[i] = oe ? data_in[i] : 1'bz;
                    end
                endcase
            end
            
            // 无流水线模式下直接传递有效信号
            assign valid_out = valid_in;
        end
    endgenerate
endmodule