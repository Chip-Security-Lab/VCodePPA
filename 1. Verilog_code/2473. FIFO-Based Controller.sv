module fifo_intr_ctrl #(
  parameter FIFO_DEPTH = 8,
  parameter PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input clk, rst_n,
  input [7:0] intr_src,
  input pop,
  output reg [2:0] intr_id,
  output empty, full
);
    reg [2:0] fifo [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [PTR_WIDTH:0] count;
    integer i;
  
    wire [7:0] edge_detect;
    reg [7:0] prev_src;
  
    assign edge_detect = intr_src & ~prev_src;
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);
  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            prev_src <= 8'h0;
            intr_id <= 3'h0;
            for (i = 0; i < FIFO_DEPTH; i = i + 1)
                fifo[i] <= 3'h0;
        end else begin
            prev_src <= intr_src;
      
            // Edge detection and FIFO write
            for (i = 0; i < 8; i = i + 1) begin
                if (edge_detect[i] && !full) begin
                    fifo[wr_ptr] <= i[2:0];
                    wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
                    count <= count + 1;
                end
            end
      
            // FIFO read on pop signal
            if (pop && !empty) begin
                intr_id <= fifo[rd_ptr];
                rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
                count <= count - 1;
            end
        end
    end
endmodule