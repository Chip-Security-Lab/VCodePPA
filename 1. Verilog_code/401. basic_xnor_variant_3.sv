//SystemVerilog
//=============================================================================
//=============================================================================
// 顶层模块：basic_xnor_pipelined
// 功能：对两个输入信号执行XNOR操作，采用流水线结构提高性能
//=============================================================================
module basic_xnor_pipelined #(
    parameter BIT_WIDTH = 1,   // 数据位宽参数
    parameter PIPELINE_STAGES = 2  // 流水线级数参数
)(
    input  wire                 clk,      // 时钟信号
    input  wire                 rst_n,    // 低电平有效复位信号
    input  wire [BIT_WIDTH-1:0] in1,      // 输入数据1
    input  wire [BIT_WIDTH-1:0] in2,      // 输入数据2
    output wire [BIT_WIDTH-1:0] out       // XNOR操作结果
);

    // 内部数据流路径信号声明
    wire [BIT_WIDTH-1:0] xor_result;
    wire [BIT_WIDTH-1:0] xor_stage_out;
    wire [BIT_WIDTH-1:0] final_xnor_value;
    
    // 流水线寄存器声明
    reg [BIT_WIDTH-1:0] in1_reg[PIPELINE_STAGES-1:0];
    reg [BIT_WIDTH-1:0] in2_reg[PIPELINE_STAGES-1:0];
    reg [BIT_WIDTH-1:0] xor_reg[PIPELINE_STAGES-2:0];
    reg [BIT_WIDTH-1:0] out_reg;
    
    // ==== 组合逻辑部分 ====
    
    // XOR操作数据路径实例化
    xor_datapath #(
        .BIT_WIDTH(BIT_WIDTH)
    ) xor_stage (
        .in1(in1_reg[0]),
        .in2(in2_reg[0]),
        .out(xor_stage_out)
    );
    
    // XNOR最终输出组合逻辑
    assign final_xnor_value = ~xor_reg[PIPELINE_STAGES-2];
    
    // 输出赋值
    assign out = out_reg;
    
    // ==== 时序逻辑部分 ====
    
    // 第一流水线级：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_reg[0] <= {BIT_WIDTH{1'b0}};
            in2_reg[0] <= {BIT_WIDTH{1'b0}};
        end else begin
            in1_reg[0] <= in1;
            in2_reg[0] <= in2;
        end
    end
    
    // 生成中间流水线级
    genvar i;
    generate
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : PIPELINE_REGS
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    in1_reg[i] <= {BIT_WIDTH{1'b0}};
                    in2_reg[i] <= {BIT_WIDTH{1'b0}};
                end else begin
                    in1_reg[i] <= in1_reg[i-1];
                    in2_reg[i] <= in2_reg[i-1];
                end
            end
        end
    endgenerate
    
    // 中间XOR结果流水线寄存器
    generate
        for (i = 0; i < PIPELINE_STAGES-1; i = i + 1) begin : XOR_PIPELINE_REGS
            if (i == 0) begin
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        xor_reg[i] <= {BIT_WIDTH{1'b0}};
                    end else begin
                        xor_reg[i] <= xor_stage_out;
                    end
                end
            end else begin
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        xor_reg[i] <= {BIT_WIDTH{1'b0}};
                    end else begin
                        xor_reg[i] <= xor_reg[i-1];
                    end
                end
            end
        end
    endgenerate
    
    // 最终输出级寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_reg <= {BIT_WIDTH{1'b0}};
        end else begin
            out_reg <= final_xnor_value;
        end
    end

endmodule

//=============================================================================
// 数据路径模块：xor_datapath
// 功能：执行XOR逻辑操作的优化数据路径
//=============================================================================
module xor_datapath #(
    parameter BIT_WIDTH = 1
)(
    input  wire [BIT_WIDTH-1:0] in1,  // 输入数据1
    input  wire [BIT_WIDTH-1:0] in2,  // 输入数据2
    output wire [BIT_WIDTH-1:0] out   // XOR操作结果
);
    
    // 纯组合逻辑实现
    generate
        if (BIT_WIDTH <= 8) begin : SMALL_WIDTH
            // 对于小位宽，直接执行XOR操作
            assign out = in1 ^ in2;
        end
        else begin : LARGE_WIDTH
            // 对于大位宽，分段计算以减少关键路径
            wire [BIT_WIDTH/2-1:0] lower_xor;
            wire [BIT_WIDTH-BIT_WIDTH/2-1:0] upper_xor;
            
            assign lower_xor = in1[BIT_WIDTH/2-1:0] ^ in2[BIT_WIDTH/2-1:0];
            assign upper_xor = in1[BIT_WIDTH-1:BIT_WIDTH/2] ^ in2[BIT_WIDTH-1:BIT_WIDTH/2];
            
            assign out = {upper_xor, lower_xor};
        end
    endgenerate
    
endmodule