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
    reg [3:0] wr_ptr_stage1, wr_ptr_stage2, rd_ptr_stage1, rd_ptr_stage2;
    reg [7:0] data_out_stage1, data_out_stage2;
    reg valid_stage1, valid_stage2;

    initial begin
        wr_ptr_stage1 = 0;
        wr_ptr_stage2 = 0;
        rd_ptr_stage1 = 0;
        rd_ptr_stage2 = 0;
        valid_stage1 = 0;
        valid_stage2 = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
            wr_ptr_stage2 <= 0;
            rd_ptr_stage1 <= 0;
            rd_ptr_stage2 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end else begin
            // Write stage
            if (wr_en && !full) begin
                buffer[wr_ptr_stage1] <= data_in;
                wr_ptr_stage1 <= wr_ptr_stage1 + 1;
                valid_stage1 <= 1;
            end else begin
                valid_stage1 <= 0;
            end

            // Update write pointer in the next stage
            wr_ptr_stage2 <= wr_ptr_stage1;

            // Read stage
            if (rd_en && !empty) begin
                rd_ptr_stage1 <= rd_ptr_stage1 + 1;
                valid_stage2 <= 1;
            end else begin
                valid_stage2 <= 0;
            end

            // Update read pointer in the next stage
            rd_ptr_stage2 <= rd_ptr_stage1;
        end
    end
    
    assign data_out = (valid_stage2) ? buffer[rd_ptr_stage2] : 8'b0;
    assign full = ((wr_ptr_stage1 - rd_ptr_stage2) == DEPTH-1) || ((wr_ptr_stage1 == 0) && (rd_ptr_stage2 == DEPTH-1));
    assign empty = (wr_ptr_stage1 == rd_ptr_stage2);
endmodule