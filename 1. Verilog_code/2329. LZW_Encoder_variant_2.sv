//SystemVerilog
//IEEE 1364-2005
module LZW_Encoder #(
    parameter DICT_DEPTH = 256,
    parameter CODE_WIDTH = 16,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,          // 添加复位信号
    input  wire                  input_valid,    // 输入数据有效信号
    input  wire [DATA_WIDTH-1:0] data,
    output reg  [CODE_WIDTH-1:0] code,
    output reg                   output_valid,   // 输出数据有效信号
    input  wire                  output_ready    // 下游模块准备接收
);

    // 字典存储
    reg [DATA_WIDTH-1:0] dict [DICT_DEPTH-1:0];
    
    // 流水线阶段1：输入捕获 - 寄存器
    reg [DATA_WIDTH-1:0] data_stage1;
    reg                  valid_stage1;
    
    // 流水线阶段2：字典查询 - 寄存器
    reg [CODE_WIDTH-1:0] current_code_stage2;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg                  valid_stage2;
    
    // 流水线阶段3：计算下一步 - 寄存器
    reg [CODE_WIDTH-1:0] current_code_stage3;
    reg [DATA_WIDTH-1:0] data_stage3;
    reg                  valid_stage3;
    reg                  match_found_stage3;
    
    // 流水线阶段4：结果输出 - 寄存器
    reg [CODE_WIDTH-1:0] current_code_stage4;
    reg [DATA_WIDTH-1:0] data_stage4;
    reg                  valid_stage4;
    reg                  output_code_stage4;

    // 当前工作代码
    reg [CODE_WIDTH-1:0] current_code;
    
    // 前递逻辑信号
    wire match_found_stage2;
    wire [CODE_WIDTH-1:0] next_code_value;
    
    // 流水线控制逻辑
    wire stall = output_valid && !output_ready;

    // ========================
    // 阶段1：输入捕获
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else if (!stall) begin
            data_stage1 <= data;
            valid_stage1 <= input_valid;
        end
    end
    
    // ========================
    // 阶段2：字典查询
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_code_stage2 <= 0;
            data_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end else if (!stall) begin
            current_code_stage2 <= current_code;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 字典比较逻辑
    assign match_found_stage2 = (dict[current_code_stage2] == data_stage2);
    
    // ========================
    // 阶段3：计算下一步
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_code_stage3 <= 0;
            data_stage3 <= 0;
            valid_stage3 <= 1'b0;
            match_found_stage3 <= 1'b0;
        end else if (!stall) begin
            current_code_stage3 <= current_code_stage2;
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
            match_found_stage3 <= match_found_stage2;
        end
    end
    
    // 条件求和减法器实现 - 完全流水线化
    wire [CODE_WIDTH-1:0] increment_value = 16'h0001;
    wire [CODE_WIDTH-1:0] inverted_increment = ~increment_value;
    wire                  carry_in = 1'b1;
    wire [CODE_WIDTH:0]   carry;
    
    assign carry[0] = carry_in;
    
    genvar i;
    generate
        for (i = 0; i < CODE_WIDTH; i = i + 1) begin : gen_adder
            assign next_code_value[i] = current_code_stage2[i] ^ inverted_increment[i] ^ carry[i];
            assign carry[i+1] = (current_code_stage2[i] & inverted_increment[i]) | 
                               (current_code_stage2[i] & carry[i]) | 
                               (inverted_increment[i] & carry[i]);
        end
    endgenerate
    
    // ========================
    // 阶段4：结果输出准备
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_code_stage4 <= 0;
            data_stage4 <= 0;
            valid_stage4 <= 1'b0;
            output_code_stage4 <= 1'b0;
        end else if (!stall) begin
            current_code_stage4 <= current_code_stage3;
            data_stage4 <= data_stage3;
            valid_stage4 <= valid_stage3;
            output_code_stage4 <= valid_stage3 && !match_found_stage3;
        end
    end
    
    // ========================
    // 输出阶段和字典更新
    // ========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_code <= 0;
            output_valid <= 1'b0;
            code <= 0;
        end else if (!stall) begin
            if (valid_stage4) begin
                if (output_code_stage4) begin
                    // 输出代码，更新字典，重置当前代码
                    code <= current_code_stage4;
                    dict[current_code_stage4] <= data_stage4;
                    current_code <= 0;
                    output_valid <= 1'b1;
                end else begin
                    // 匹配情况：更新当前代码
                    current_code <= ~next_code_value;
                    output_valid <= 1'b0;
                end
            end else begin
                output_valid <= 1'b0;
            end
        end else if (output_ready) begin
            // 当下游准备好接收时清除输出有效信号
            output_valid <= 1'b0;
        end
    end

endmodule