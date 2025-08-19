//SystemVerilog
module ElasticBufferBridge #(
    parameter DEPTH=8
)(
    input clk, rst_n,
    input [7:0] data_in,
    input wr_en, rd_en,
    output [7:0] data_out,
    output full, empty
);
    reg [7:0] buffer [0:DEPTH-1];
    reg [3:0] wr_ptr, rd_ptr;
    
    initial begin
        wr_ptr = 0;
        rd_ptr = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            buffer[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign data_out = buffer[rd_ptr];
    
    // 借位减法器实现判断满状态逻辑
    wire [3:0] diff;
    wire [4:0] borrow;
    
    assign borrow[0] = 1'b0;
    assign diff[0] = wr_ptr[0] ^ rd_ptr[0] ^ borrow[0];
    assign borrow[1] = (~wr_ptr[0] & rd_ptr[0]) | (~wr_ptr[0] & borrow[0]) | (rd_ptr[0] & borrow[0]);
    
    assign diff[1] = wr_ptr[1] ^ rd_ptr[1] ^ borrow[1];
    assign borrow[2] = (~wr_ptr[1] & rd_ptr[1]) | (~wr_ptr[1] & borrow[1]) | (rd_ptr[1] & borrow[1]);
    
    assign diff[2] = wr_ptr[2] ^ rd_ptr[2] ^ borrow[2];
    assign borrow[3] = (~wr_ptr[2] & rd_ptr[2]) | (~wr_ptr[2] & borrow[2]) | (rd_ptr[2] & borrow[2]);
    
    assign diff[3] = wr_ptr[3] ^ rd_ptr[3] ^ borrow[3];
    assign borrow[4] = (~wr_ptr[3] & rd_ptr[3]) | (~wr_ptr[3] & borrow[3]) | (rd_ptr[3] & borrow[3]);
    
    assign full = (diff == DEPTH-1) || ((wr_ptr == 0) && (rd_ptr == DEPTH-1));
    assign empty = (wr_ptr == rd_ptr);
endmodule