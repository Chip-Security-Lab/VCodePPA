//SystemVerilog
module LUT_Hamming_Encoder(
    input wire clk,              
    input wire rst_n,            
    input wire enable,           
    input wire [3:0] data_in,    
    output reg [6:0] code_out,   
    output reg valid_out         
);
    // 使用参数定义常量
    localparam LUT_DEPTH = 16;
    localparam CODE_WIDTH = 7;
    
    // 优化ROM访问方式
    (* ram_style = "distributed" *) reg [CODE_WIDTH-1:0] ham_rom [0:LUT_DEPTH-1];
    
    // 用于流水线的控制信号传递
    reg enable_stage1, enable_stage2;
    
    // 优化数据流
    reg [3:0] data_reg;
    wire [6:0] code_next;
    
    // 初始化ROM内容
    initial begin
        $readmemh("hamming_lut.hex", ham_rom);
    end
    
    // 第一级：输入数据寄存和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 4'b0;
            enable_stage1 <= 1'b0;
        end else begin
            data_reg <= enable ? data_in : data_reg;
            enable_stage1 <= enable;
        end
    end
    
    // 使用连续赋值实现ROM读取，减少一级寄存
    assign code_next = ham_rom[data_reg];
    
    // 第二级：控制信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
        end
    end
    
    // 输出级：直接从ROM读取并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= {CODE_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            code_out <= code_next;
            valid_out <= enable_stage2;
        end
    end
endmodule