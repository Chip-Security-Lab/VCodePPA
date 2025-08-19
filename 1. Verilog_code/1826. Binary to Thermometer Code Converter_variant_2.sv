//SystemVerilog
module bin2thermometer #(parameter BIN_WIDTH = 3) (
    input                       clk,        // 添加时钟输入
    input                       rst_n,      // 添加复位信号
    input      [BIN_WIDTH-1:0]  bin_input,
    output reg [(2**BIN_WIDTH)-2:0] therm_output
);
    // 分割数据流路径为多个阶段
    reg [BIN_WIDTH-1:0] bin_input_reg;
    reg [(2**BIN_WIDTH)-2:0] therm_stage1;
    
    // 第一阶段：寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_input_reg <= {BIN_WIDTH{1'b0}};
        end else begin
            bin_input_reg <= bin_input;
        end
    end
    
    // 第二阶段：低半部分转换
    wire [(2**BIN_WIDTH)/2-1:0] lower_half;
    genvar i;
    generate
        for (i = 0; i < (2**BIN_WIDTH)/2; i = i + 1) begin : gen_lower
            assign lower_half[i] = (i < bin_input_reg) ? 1'b1 : 1'b0;
        end
    endgenerate
    
    // 第二阶段：高半部分转换
    wire [(2**BIN_WIDTH)/2-1:0] upper_half;
    generate
        for (i = (2**BIN_WIDTH)/2; i < 2**BIN_WIDTH-1; i = i + 1) begin : gen_upper
            assign upper_half[i-(2**BIN_WIDTH)/2] = (i < bin_input_reg) ? 1'b1 : 1'b0;
        end
    endgenerate
    
    // 第三阶段：合并结果并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            therm_stage1 <= {(2**BIN_WIDTH-1){1'b0}};
        end else begin
            therm_stage1 <= {upper_half, lower_half};
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            therm_output <= {(2**BIN_WIDTH-1){1'b0}};
        end else begin
            therm_output <= therm_stage1;
        end
    end
    
endmodule