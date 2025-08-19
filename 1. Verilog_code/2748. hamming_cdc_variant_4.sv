//SystemVerilog
module hamming_cdc(
    input clk_in, clk_out, rst_n,
    input [3:0] data_in,
    input valid_in,
    output ready_in,
    output reg [6:0] encoded_out,
    output reg valid_out,
    input ready_out
);
    reg [3:0] data_reg;
    reg [6:0] encoded;
    reg valid_in_sync1, valid_in_sync2;
    reg ready_out_sync1, ready_out_sync2;
    reg valid_internal;
    reg data_processed;
    
    // Ready信号生成 - 输入时钟域
    assign ready_in = ~data_processed || ready_out_sync2;
    
    // 输入时钟域 - 数据寄存和处理控制
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 4'b0;
            data_processed <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                data_reg <= data_in;
                data_processed <= 1'b1;
            end else if (ready_out_sync2 && data_processed) begin
                data_processed <= 1'b0;
            end
        end
    end
    
    // 汉明编码计算 - 输入时钟域
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 7'b0;
            valid_internal <= 1'b0;
        end else if (valid_in && ready_in) begin
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
            valid_internal <= 1'b1;
        end else if (ready_out_sync2 && valid_internal) begin
            valid_internal <= 1'b0;
        end
    end
    
    // Valid信号跨时钟域
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_sync1 <= 1'b0;
            valid_in_sync2 <= 1'b0;
        end else begin
            valid_in_sync1 <= valid_internal;
            valid_in_sync2 <= valid_in_sync1;
        end
    end
    
    // Ready信号跨时钟域 (从输出域到输入域)
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            ready_out_sync1 <= 1'b0;
            ready_out_sync2 <= 1'b0;
        end else begin
            ready_out_sync1 <= ready_out;
            ready_out_sync2 <= ready_out_sync1;
        end
    end
    
    // 输出时钟域 - 数据和valid信号输出
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
            valid_out <= 1'b0;
        end else if (valid_in_sync2 && ready_out) begin
            encoded_out <= encoded;
            valid_out <= 1'b1;
        end else if (ready_out && valid_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule