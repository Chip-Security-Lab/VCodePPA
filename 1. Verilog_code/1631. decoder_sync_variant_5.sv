//SystemVerilog
// 顶层模块
module decoder_sync #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] data
);

    // 内部信号定义
    wire [1:0] decode_sel;
    wire [DATA_WIDTH-1:0] data_next;
    wire data_valid;

    // 地址解码器实例化
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_decoder_inst (
        .addr(addr),
        .decode_sel(decode_sel),
        .valid(data_valid)
    );

    // 数据生成器实例化
    data_generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_generator_inst (
        .decode_sel(decode_sel),
        .data_out(data_next)
    );

    // 输出寄存器实例化
    output_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_register_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_next),
        .valid(data_valid),
        .data_out(data)
    );

endmodule

// 地址解码器子模块
module addr_decoder #(
    parameter ADDR_WIDTH = 4
) (
    input [ADDR_WIDTH-1:0] addr,
    output reg [1:0] decode_sel,
    output reg valid
);

    always @(*) begin
        case(addr[3:0])
            4'h0: begin
                decode_sel = 2'b01;
                valid = 1'b1;
            end
            4'h4: begin
                decode_sel = 2'b10;
                valid = 1'b1;
            end
            default: begin
                decode_sel = 2'b00;
                valid = 1'b0;
            end
        endcase
    end

endmodule

// 数据生成器子模块
module data_generator #(
    parameter DATA_WIDTH = 8
) (
    input [1:0] decode_sel,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(*) begin
        case(decode_sel)
            2'b01: data_out = 8'h01;
            2'b10: data_out = 8'h02;
            default: data_out = 8'h00;
        endcase
    end

endmodule

// 输出寄存器子模块
module output_register #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input valid,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (valid) begin
            data_out <= data_in;
        end
    end

endmodule