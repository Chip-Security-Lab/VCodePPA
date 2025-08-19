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
    reg valid_src, valid_sync1, valid_sync2;
    reg ready_dst, ready_sync1, ready_sync2;
    wire ready_src;
    
    // 源域数据和有效信号寄存
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 4'b0;
            valid_src <= 1'b0;
        end else if (valid_in && ready_in) begin
            data_reg <= data_in;
            valid_src <= 1'b1;
        end else if (ready_src) begin
            valid_src <= 1'b0;
        end
    end
    
    // 汉明编码逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 7'b0;
        end else if (valid_in && ready_in) begin
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
        end
    end
    
    // 目标域到源域的ready信号同步
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            ready_sync1 <= 1'b0;
            ready_sync2 <= 1'b0;
        end else begin
            ready_sync1 <= ready_dst;
            ready_sync2 <= ready_sync1;
        end
    end
    
    // 源域到目标域的valid信号同步
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            valid_sync1 <= 1'b0;
            valid_sync2 <= 1'b0;
        end else begin
            valid_sync1 <= valid_src;
            valid_sync2 <= valid_sync1;
        end
    end
    
    // 目标域的输出控制
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
            valid_out <= 1'b0;
            ready_dst <= 1'b1;
        end else if (valid_sync2 && ready_out && ready_dst) begin
            encoded_out <= encoded;
            valid_out <= 1'b1;
            ready_dst <= 1'b0;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
            ready_dst <= 1'b1;
        end
    end
    
    // 反馈信号生成
    assign ready_src = ready_sync2;
    assign ready_in = !valid_src || ready_src;
    
endmodule