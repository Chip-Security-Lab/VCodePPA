//SystemVerilog
module bin2thermometer #(parameter BIN_WIDTH = 3) (
    input  wire                    clk,        // 添加时钟信号用于流水线寄存器
    input  wire                    rst_n,      // 添加复位信号
    input  wire [BIN_WIDTH-1:0]    bin_input,
    output reg  [(2**BIN_WIDTH)-2:0] therm_output
);
    // 声明内部信号，用于构建清晰的数据流
    reg [BIN_WIDTH-1:0] bin_input_reg;
    wire [(2**BIN_WIDTH)-2:0] therm_stage1;
    reg [(2**BIN_WIDTH)-2:0] therm_stage2;
    
    // 第一级寄存器 - 捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_input_reg <= {BIN_WIDTH{1'b0}};
        else
            bin_input_reg <= bin_input;
    end
    
    // 热敏码转换 - 使用借位减法器实现比较逻辑
    genvar i;
    generate
        for (i = 0; i < (2**BIN_WIDTH)-1; i = i + 1) begin : gen_therm
            // 声明每个位置的借位链
            wire [BIN_WIDTH:0] borrow;
            wire [BIN_WIDTH-1:0] diff;
            
            // 初始借位为0
            assign borrow[0] = 1'b0;
            
            // 借位减法器实现
            genvar j;
            for (j = 0; j < BIN_WIDTH; j = j + 1) begin : gen_sub_bit
                // 计算差值：A - B - borrow_in
                assign diff[j] = bin_input_reg[j] ^ (i[j]) ^ borrow[j];
                // 计算借位：当前位产生借位的条件
                assign borrow[j+1] = (~bin_input_reg[j] & i[j]) | 
                                     (~bin_input_reg[j] & borrow[j]) | 
                                     (i[j] & borrow[j]);
            end
            
            // 根据最终借位判断大小关系
            // 如果有借位，说明bin_input_reg < i，结果应为0
            // 如果无借位，说明bin_input_reg >= i，结果应为1
            assign therm_stage1[i] = ~borrow[BIN_WIDTH];
        end
    endgenerate
    
    // 第二级寄存器 - 捕获组合逻辑输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            therm_stage2 <= {(2**BIN_WIDTH)-1{1'b0}};
        else
            therm_stage2 <= therm_stage1;
    end
    
    // 输出赋值 - 最终阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            therm_output <= {(2**BIN_WIDTH)-1{1'b0}};
        else
            therm_output <= therm_stage2;
    end
    
endmodule