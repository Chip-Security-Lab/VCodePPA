//SystemVerilog
module LUT_Hamming_Encoder(
    input wire clk,
    input wire rst_n,
    input wire [3:0] data_in,
    input wire data_valid,
    output wire [6:0] code_out,
    output wire code_valid
);
    // 中间信号声明
    wire [3:0] data_stage1;
    wire data_valid_stage1;
    wire [6:0] code_stage2;
    wire code_valid_stage2;
    
    // 输入寄存器阶段
    data_input_stage input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_stage1),
        .data_valid_out(data_valid_stage1)
    );
    
    // 汉明编码查找阶段
    hamming_lookup_stage lookup_stage (
        .clk(clk),
        .rst_n(rst_n),
        .addr_in(data_stage1),
        .addr_valid(data_valid_stage1),
        .code_out(code_stage2),
        .code_valid(code_valid_stage2)
    );
    
    // 输出寄存器阶段
    output_register_stage output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .code_in(code_stage2),
        .code_valid_in(code_valid_stage2),
        .code_out(code_out),
        .code_valid_out(code_valid)
    );
endmodule

module data_input_stage (
    input wire clk,
    input wire rst_n,
    input wire [3:0] data_in,
    input wire data_valid,
    output reg [3:0] data_out,
    output reg data_valid_out
);
    // 输入寄存器实现，添加一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 4'b0;
            data_valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            data_valid_out <= data_valid;
        end
    end
endmodule

module hamming_lookup_stage (
    input wire clk,
    input wire rst_n,
    input wire [3:0] addr_in,
    input wire addr_valid,
    output reg [6:0] code_out,
    output reg code_valid
);
    // ROM存储预计算的汉明码结果
    reg [6:0] ham_rom [0:15];
    
    // 初始化ROM内容
    initial begin
        $readmemh("hamming_lut.hex", ham_rom);
    end
    
    // 使用寄存器输出以提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= 7'b0;
            code_valid <= 1'b0;
        end else begin
            code_out <= ham_rom[addr_in];
            code_valid <= addr_valid;
        end
    end
endmodule

module output_register_stage (
    input wire clk,
    input wire rst_n,
    input wire [6:0] code_in,
    input wire code_valid_in,
    output reg [6:0] code_out,
    output reg code_valid_out
);
    // 输出寄存器实现，添加额外的流水线级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= 7'b0;
            code_valid_out <= 1'b0;
        end else begin
            code_out <= code_in;
            code_valid_out <= code_valid_in;
        end
    end
endmodule