//SystemVerilog
// 顶层模块
module ParamHamming_Encoder #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH+4:0] code_out
);
    // 参数定义
    parameter PARITY_BITS = 4;
    
    // 内部信号
    wire [DATA_WIDTH-1:0] data_reg;
    wire [PARITY_BITS-1:0] parity;
    wire [DATA_WIDTH+4:0] encoded_data;
    
    // 寄存器子模块
    DataRegister #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_reg_inst (
        .clk(clk),
        .en(en),
        .data_in(data_in),
        .data_out(data_reg)
    );
    
    // 校验位计算子模块
    ParityGenerator #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS)
    ) parity_gen_inst (
        .clk(clk),
        .en(en),
        .data_in(data_in),
        .parity_out(parity)
    );
    
    // 码字组装子模块
    CodeAssembler #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS)
    ) code_assembler_inst (
        .clk(clk),
        .en(en),
        .data_in(data_reg),
        .parity_in(parity),
        .code_out(code_out)
    );
    
endmodule

// 数据寄存器子模块
module DataRegister #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if(en) begin
            data_out <= data_in;
        end
    end
endmodule

// 校验位生成子模块
module ParityGenerator #(
    parameter DATA_WIDTH = 8,
    parameter PARITY_BITS = 4
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [PARITY_BITS-1:0] parity_out
);
    integer i, j, mask;
    
    always @(posedge clk) begin
        if(en) begin
            // 计算校验位
            for(i=0; i<PARITY_BITS; i=i+1) begin
                mask = (1 << i);
                parity_out[i] = 0;
                for(j=0; j<DATA_WIDTH; j=j+1) begin
                    if((j+1) & mask) 
                        parity_out[i] = parity_out[i] ^ data_in[j];
                end
            end
        end
    end
endmodule

// 码字组装子模块
module CodeAssembler #(
    parameter DATA_WIDTH = 8,
    parameter PARITY_BITS = 4
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    input [PARITY_BITS-1:0] parity_in,
    output reg [DATA_WIDTH+4:0] code_out
);
    integer i, j;
    
    always @(posedge clk) begin
        if(en) begin
            // 组合输出
            code_out[0] <= parity_in[0];
            code_out[1] <= parity_in[1];
            code_out[3] <= parity_in[2];
            code_out[7] <= parity_in[3];
            
            // 插入数据位
            j = 0;
            for(i=0; i<DATA_WIDTH+5; i=i+1) begin
                if(i != 0 && i != 1 && i != 3 && i != 7) begin
                    if(j < DATA_WIDTH) begin
                        code_out[i] <= data_in[j];
                        j = j + 1;
                    end
                end
            end
        end
    end
endmodule