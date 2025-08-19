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
    reg [3:0] wr_ptr_buf, rd_ptr_buf; // Buffer registers for high fanout signals
    reg [3:0] wr_ptr_reg, rd_ptr_reg; // Additional registers for load balancing

    initial begin
        wr_ptr = 0;
        rd_ptr = 0;
        wr_ptr_buf = 0;
        rd_ptr_buf = 0;
        wr_ptr_reg = 0;
        rd_ptr_reg = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_ptr_buf <= 0;
            rd_ptr_buf <= 0;
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
        end else begin
            if (wr_en && !full) begin
                buffer[wr_ptr] <= data_in;
                wr_ptr_reg <= wr_ptr; // Update register pointer
                wr_ptr_buf <= wr_ptr_reg; // Update buffer pointer
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr_reg <= rd_ptr; // Update register pointer
                rd_ptr_buf <= rd_ptr_reg; // Update buffer pointer
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
    
    assign data_out = buffer[rd_ptr_buf]; // Use buffered read pointer
    assign full = ((wr_ptr_buf - rd_ptr_buf) == DEPTH-1) || ((wr_ptr_buf == 0) && (rd_ptr_buf == DEPTH-1)); // Use buffered pointers
    assign empty = (wr_ptr_buf == rd_ptr_buf); // Use buffered pointers
endmodule