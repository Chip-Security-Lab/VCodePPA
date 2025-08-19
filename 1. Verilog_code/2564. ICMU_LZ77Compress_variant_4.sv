//SystemVerilog
// 顶层模块
module ICMU_LZ77Compress #(
    parameter RAW_WIDTH = 64,
    parameter COMP_WIDTH = 32
)(
    input clk,
    input rst_n,
    input compress_en,
    input [RAW_WIDTH-1:0] raw_data,
    output reg [COMP_WIDTH-1:0] comp_data,
    output reg comp_valid
);

    // 内部信号
    wire compress_en_stage1, compress_en_stage2, compress_en_stage3;
    wire [RAW_WIDTH-1:0] raw_data_stage1, raw_data_stage2;
    wire [7:0] match_length_stage2;
    wire [2:0] match_distance_stage2;
    wire [7:0] literal_stage2;
    wire [COMP_WIDTH-1:0] comp_data_stage3;
    wire comp_valid_stage3;

    // 实例化子模块
    ICMU_LZ77_InputStage #(
        .RAW_WIDTH(RAW_WIDTH)
    ) input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .compress_en(compress_en),
        .raw_data(raw_data),
        .compress_en_out(compress_en_stage1),
        .raw_data_out(raw_data_stage1)
    );

    ICMU_LZ77_MatchStage #(
        .RAW_WIDTH(RAW_WIDTH)
    ) match_stage (
        .clk(clk),
        .rst_n(rst_n),
        .compress_en_in(compress_en_stage1),
        .raw_data_in(raw_data_stage1),
        .compress_en_out(compress_en_stage2),
        .raw_data_out(raw_data_stage2),
        .match_length(match_length_stage2),
        .match_distance(match_distance_stage2),
        .literal(literal_stage2)
    );

    ICMU_LZ77_CompressStage #(
        .COMP_WIDTH(COMP_WIDTH)
    ) compress_stage (
        .clk(clk),
        .rst_n(rst_n),
        .compress_en_in(compress_en_stage2),
        .match_length(match_length_stage2),
        .match_distance(match_distance_stage2),
        .literal(literal_stage2),
        .compress_en_out(compress_en_stage3),
        .comp_data(comp_data_stage3),
        .comp_valid(comp_valid_stage3)
    );

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_data <= {COMP_WIDTH{1'b0}};
            comp_valid <= 1'b0;
        end else begin
            comp_data <= comp_data_stage3;
            comp_valid <= comp_valid_stage3;
        end
    end
endmodule

// 输入处理子模块
module ICMU_LZ77_InputStage #(
    parameter RAW_WIDTH = 64
)(
    input clk,
    input rst_n,
    input compress_en,
    input [RAW_WIDTH-1:0] raw_data,
    output reg compress_en_out,
    output reg [RAW_WIDTH-1:0] raw_data_out
);

    reg [RAW_WIDTH-1:0] search_buffer [0:7];
    reg [2:0] wr_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compress_en_out <= 1'b0;
            raw_data_out <= {RAW_WIDTH{1'b0}};
            wr_ptr <= 3'b0;
            for (integer i = 0; i < 8; i = i + 1)
                search_buffer[i] <= {RAW_WIDTH{1'b0}};
        end else begin
            compress_en_out <= compress_en;
            raw_data_out <= raw_data;
            
            if (compress_en) begin
                search_buffer[wr_ptr] <= raw_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end
endmodule

// 匹配查找子模块
module ICMU_LZ77_MatchStage #(
    parameter RAW_WIDTH = 64
)(
    input clk,
    input rst_n,
    input compress_en_in,
    input [RAW_WIDTH-1:0] raw_data_in,
    output reg compress_en_out,
    output reg [RAW_WIDTH-1:0] raw_data_out,
    output reg [7:0] match_length,
    output reg [2:0] match_distance,
    output reg [7:0] literal
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compress_en_out <= 1'b0;
            raw_data_out <= {RAW_WIDTH{1'b0}};
            match_length <= 8'b0;
            match_distance <= 3'b0;
            literal <= 8'b0;
        end else begin
            compress_en_out <= compress_en_in;
            raw_data_out <= raw_data_in;
            
            if (compress_en_in) begin
                match_length <= 3'b001;
                match_distance <= 3'b000;
                literal <= raw_data_in[7:0];
            end
        end
    end
endmodule

// 压缩数据生成子模块
module ICMU_LZ77_CompressStage #(
    parameter COMP_WIDTH = 32
)(
    input clk,
    input rst_n,
    input compress_en_in,
    input [7:0] match_length,
    input [2:0] match_distance,
    input [7:0] literal,
    output reg compress_en_out,
    output reg [COMP_WIDTH-1:0] comp_data,
    output reg comp_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compress_en_out <= 1'b0;
            comp_data <= {COMP_WIDTH{1'b0}};
            comp_valid <= 1'b0;
        end else begin
            compress_en_out <= compress_en_in;
            
            if (compress_en_in) begin
                comp_data <= {match_length, match_distance, literal};
                comp_valid <= 1'b1;
            end else begin
                comp_valid <= 1'b0;
            end
        end
    end
endmodule