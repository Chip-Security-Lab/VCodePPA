//SystemVerilog
module mux_based_shifter (
    input  wire        clk,       // 添加时钟信号用于流水线寄存器
    input  wire        rst_n,     // 添加复位信号用于流水线寄存器
    input  wire [7:0]  data,      // 输入数据
    input  wire [2:0]  shift,     // 移位控制信号
    output wire [7:0]  result     // 输出结果
);

    // 第一级流水线信号
    reg  [7:0] data_reg;          // 输入数据寄存器
    reg  [2:0] shift_reg;         // 移位控制寄存器
    
    // 第二级流水线信号
    reg  [7:0] stage1_reg;        // 第一阶段移位结果寄存器
    reg  [1:0] shift_remain_reg;  // 剩余移位控制信号
    
    // 第三级流水线信号
    reg  [7:0] stage2_reg;        // 第二阶段移位结果寄存器
    reg        shift_final_reg;   // 最后阶段移位控制位
    
    // 组合逻辑信号
    wire [7:0] stage1_data;       // 第一阶段移位组合逻辑结果
    wire [7:0] stage2_data;       // 第二阶段移位组合逻辑结果
    wire [7:0] stage3_data;       // 第三阶段移位组合逻辑结果
    
    // 第一阶段移位逻辑 - 移位1位
    assign stage1_data = shift_reg[0] ? {data_reg[6:0], data_reg[7]} : data_reg;
    
    // 第二阶段移位逻辑 - 移位2位
    assign stage2_data = shift_remain_reg[0] ? {stage1_reg[5:0], stage1_reg[7:6]} : stage1_reg;
    
    // 第三阶段移位逻辑 - 移位4位
    assign stage3_data = shift_final_reg ? {stage2_reg[3:0], stage2_reg[7:4]} : stage2_reg;
    
    // 输出赋值
    assign result = stage3_data;
    
    // 流水线寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 第一级流水线复位
            data_reg        <= 8'h0;
            shift_reg       <= 3'h0;
            
            // 第二级流水线复位
            stage1_reg      <= 8'h0;
            shift_remain_reg <= 2'h0;
            
            // 第三级流水线复位
            stage2_reg      <= 8'h0;
            shift_final_reg <= 1'b0;
        end else begin
            // 第一级流水线
            data_reg        <= data;
            shift_reg       <= shift;
            
            // 第二级流水线
            stage1_reg      <= stage1_data;
            shift_remain_reg <= shift_reg[2:1];
            
            // 第三级流水线
            stage2_reg      <= stage2_data;
            shift_final_reg <= shift_remain_reg[1];
        end
    end

endmodule