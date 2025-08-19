//SystemVerilog
// 顶层模块
module arith_extend (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号，低电平有效
    input wire [3:0] operand,
    output wire [4:0] inc,
    output wire [4:0] dec
);
    // 内部连接信号
    wire [3:0] operand_reg;
    wire [4:0] inc_calc;
    wire [4:0] dec_calc;
    
    // 实例化操作数寄存器模块
    operand_register operand_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .operand_in(operand),
        .operand_out(operand_reg)
    );
    
    // 实例化计算模块
    arithmetic_calculator calc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .operand(operand_reg),
        .inc_out(inc_calc),
        .dec_out(dec_calc)
    );
    
    // 实例化输出寄存器模块
    output_register out_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .inc_in(inc_calc),
        .dec_in(dec_calc),
        .inc_out(inc),
        .dec_out(dec)
    );
endmodule

// 操作数寄存器模块
module operand_register (
    input wire clk,
    input wire rst_n,
    input wire [3:0] operand_in,
    output reg [3:0] operand_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_out <= 4'b0;
        end else begin
            operand_out <= operand_in;
        end
    end
endmodule

// 算术计算模块
module arithmetic_calculator (
    input wire clk,
    input wire rst_n,
    input wire [3:0] operand,
    output reg [4:0] inc_out,
    output reg [4:0] dec_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inc_out <= 5'b0;
            dec_out <= 5'b0;
        end else begin
            inc_out <= {1'b0, operand} + 5'b1;
            dec_out <= {1'b0, operand} - 5'b1;
        end
    end
endmodule

// 输出寄存器模块
module output_register (
    input wire clk,
    input wire rst_n,
    input wire [4:0] inc_in,
    input wire [4:0] dec_in,
    output reg [4:0] inc_out,
    output reg [4:0] dec_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inc_out <= 5'b0;
            dec_out <= 5'b0;
        end else begin
            inc_out <= inc_in;
            dec_out <= dec_in;
        end
    end
endmodule