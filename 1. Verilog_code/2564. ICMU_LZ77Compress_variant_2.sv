//SystemVerilog
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

    // 搜索缓冲区寄存器
    reg [RAW_WIDTH-1:0] search_buffer [0:7];
    reg [2:0] wr_ptr;
    
    // 匹配结果寄存器
    reg [2:0] match_len;
    reg [2:0] match_dist;
    reg [7:0] literal;
    
    // 并行比较逻辑
    wire [7:0] match_len_w [0:7];
    wire [2:0] match_dist_w [0:7];
    
    // 生成比较器
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : COMPARE_GEN
            assign match_len_w[i] = (search_buffer[i] == raw_data) ? 8'd1 : 8'd0;
            assign match_dist_w[i] = i;
        end
    endgenerate
    
    // 查找最长匹配逻辑
    always @(*) begin
        match_len = 0;
        match_dist = 0;
        for (int j = 0; j < 8; j = j + 1) begin
            if (match_len_w[j] > match_len) begin
                match_len = match_len_w[j];
                match_dist = match_dist_w[j];
            end
        end
    end
    
    // 搜索缓冲区更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            for (int k = 0; k < 8; k = k + 1) begin
                search_buffer[k] <= 0;
            end
        end else if (compress_en) begin
            search_buffer[wr_ptr] <= raw_data;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // 压缩数据输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_data <= 0;
            comp_valid <= 0;
        end else if (compress_en) begin
            comp_data <= {match_len, match_dist, raw_data[7:0]};
            comp_valid <= 1;
        end else begin
            comp_valid <= 0;
        end
    end
endmodule