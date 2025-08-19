//SystemVerilog
// 顶层模块，协调整个汉明编码生成过程
module hamming_parity_precalc(
    input clk, en,
    input [3:0] data,
    output [6:0] code
);
    // 内部连线，连接子模块
    wire [2:0] parity_bits;
    wire [3:0] data_reg;
    
    // 数据寄存器模块实例化
    data_register data_reg_inst (
        .clk(clk),
        .en(en),
        .data_in(data),
        .data_out(data_reg)
    );
    
    // 奇偶校验计算模块实例化
    parity_calculator parity_calc_inst (
        .clk(clk),
        .en(en),
        .data(data),
        .parity_bits(parity_bits)
    );
    
    // 编码组装模块实例化
    code_assembler code_assem_inst (
        .clk(clk),
        .en(en),
        .data(data_reg),
        .parity_bits(parity_bits),
        .code(code)
    );
endmodule

// 数据寄存器模块，对输入数据进行缓存
module data_register (
    input clk, en,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(posedge clk) begin
        if (en) begin
            data_out <= data_in;
        end
    end
endmodule

// 奇偶校验位计算模块，计算所有奇偶校验位
module parity_calculator (
    input clk, en,
    input [3:0] data,
    output reg [2:0] parity_bits
);
    always @(posedge clk) begin
        if (en) begin
            // P1, P2, P4 奇偶校验位计算
            parity_bits[0] <= data[0] ^ data[1] ^ data[3]; // P1
            parity_bits[1] <= data[0] ^ data[2] ^ data[3]; // P2
            parity_bits[2] <= data[1] ^ data[2] ^ data[3]; // P4
        end
    end
endmodule

// 编码组装模块，将数据位和奇偶校验位组装成完整编码
module code_assembler (
    input clk, en,
    input [3:0] data,
    input [2:0] parity_bits,
    output reg [6:0] code
);
    always @(posedge clk) begin
        if (en) begin
            // 按汉明码格式组装: {d3,d2,d1,p4,d0,p2,p1}
            code <= {data[3:1], parity_bits[2], data[0], parity_bits[1], parity_bits[0]};
        end
    end
endmodule