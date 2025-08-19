//SystemVerilog
module incrementers (
    input wire clk,
    input wire rst_n,
    input wire [5:0] base,
    output reg [5:0] double,
    output reg [5:0] triple
);

    // 中间信号
    reg [5:0] base_reg;
    reg [5:0] base_shift;
    reg [5:0] double_comb;
    reg [5:0] triple_comb;
    
    // 缓冲寄存器
    reg [5:0] base_reg_buf;
    reg [5:0] base_shift_buf;
    
    // 第一级流水线：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_reg <= 6'b0;
            base_shift <= 6'b0;
        end else begin
            base_reg <= base;
            base_shift <= base << 1;
        end
    end
    
    // 缓冲级：分散扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_reg_buf <= 6'b0;
            base_shift_buf <= 6'b0;
        end else begin
            base_reg_buf <= base_reg;
            base_shift_buf <= base_shift;
        end
    end
    
    // 组合逻辑：使用缓冲后的信号
    always @(*) begin
        double_comb = base_shift_buf;
        triple_comb = base_reg_buf + base_shift_buf;
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            double <= 6'b0;
            triple <= 6'b0;
        end else begin
            double <= double_comb;
            triple <= triple_comb;
        end
    end

endmodule