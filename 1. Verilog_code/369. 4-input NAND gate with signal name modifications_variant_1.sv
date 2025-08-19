//SystemVerilog
module nand4_5 (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 低电平有效复位信号
    input  wire        A1,       // 第一输入
    input  wire        B1,       // 第二输入
    input  wire        C1,       // 第三输入
    input  wire        D1,       // 第四输入
    output wire        Y         // 输出: NAND结果
);

    // 内部信号声明 - 流水线寄存器和组合逻辑路径
    reg  A1_reg, B1_reg, C1_reg, D1_reg;        // 输入寄存器级
    reg  stage1_AB_reg, stage1_CD_reg;          // 第一级中间结果寄存器
    reg  stage2_ABCD_reg;                       // 第二级中间结果寄存器
    reg  Y_reg;                                 // 输出寄存器
    
    wire stage1_AB_wire, stage1_CD_wire;        // 组合逻辑中间结果
    wire stage2_ABCD_wire;                      // 最终组合逻辑结果
    
    // 输入寄存器级 - 隔离外部信号，改善建立时间
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A1_reg <= 1'b0;
            B1_reg <= 1'b0;
            C1_reg <= 1'b0;
            D1_reg <= 1'b0;
        end else begin
            A1_reg <= A1;
            B1_reg <= B1;
            C1_reg <= C1;
            D1_reg <= D1;
        end
    end
    
    // 流水线第一级 - 并行化前期逻辑运算，减少关键路径延迟
    assign stage1_AB_wire = A1_reg & B1_reg;   // A和B的并行AND运算
    assign stage1_CD_wire = C1_reg & D1_reg;   // C和D的并行AND运算
    
    // 流水线第一级寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_AB_reg <= 1'b0;
            stage1_CD_reg <= 1'b0;
        end else begin
            stage1_AB_reg <= stage1_AB_wire;
            stage1_CD_reg <= stage1_CD_wire;
        end
    end
    
    // 流水线第二级 - 合并中间结果
    assign stage2_ABCD_wire = stage1_AB_reg & stage1_CD_reg;
    
    // 流水线第二级寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_ABCD_reg <= 1'b0;
        end else begin
            stage2_ABCD_reg <= stage2_ABCD_wire;
        end
    end
    
    // 输出级 - NAND操作并寄存输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 1'b1;  // NAND门复位时输出1
        end else begin
            Y_reg <= ~stage2_ABCD_reg;
        end
    end
    
    // 输出赋值
    assign Y = Y_reg;
    
endmodule