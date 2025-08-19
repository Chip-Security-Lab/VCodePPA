//SystemVerilog
module fifo_arbiter(
  input wire clk, rst_n,
  input wire [3:0] request,
  input wire new_req,
  output reg [3:0] grant,
  output wire empty
);
  // FIFO storage and pointers
  reg [3:0] fifo [0:3];
  reg [1:0] wr_ptr, rd_ptr;
  
  // Pipeline registers for multi-stage processing
  reg new_req_stage1, new_req_stage2;
  reg [3:0] request_stage1;
  reg [1:0] rd_ptr_stage1;
  reg fifo_read_valid_stage1, fifo_read_valid_stage2;
  reg [3:0] fifo_data_stage1, fifo_data_stage2;
  
  // FIFO empty signal
  assign empty = (wr_ptr == rd_ptr);
  
  // Stage 1: Request capture and FIFO write logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 2'b00;
      new_req_stage1 <= 1'b0;
      request_stage1 <= 4'b0000;
    end else begin
      // Capture incoming request
      new_req_stage1 <= new_req;
      request_stage1 <= request;
      
      // Write to FIFO if new request
      if (new_req) begin
        fifo[wr_ptr] <= request;
        wr_ptr <= wr_ptr + 2'b01;
      end
    end
  end
  
  // Stage 2: FIFO read logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 2'b00;
      rd_ptr_stage1 <= 2'b00;
      fifo_read_valid_stage1 <= 1'b0;
      fifo_data_stage1 <= 4'b0000;
    end else begin
      rd_ptr_stage1 <= rd_ptr;
      
      // Determine if we should read from FIFO
      if (!empty) begin
        fifo_read_valid_stage1 <= 1'b1;
        fifo_data_stage1 <= fifo[rd_ptr];
        rd_ptr <= rd_ptr + 2'b01;
      end else begin
        fifo_read_valid_stage1 <= 1'b0;
      end
    end
  end
  
  // Stage 3: Grant generation logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_read_valid_stage2 <= 1'b0;
      fifo_data_stage2 <= 4'b0000;
      new_req_stage2 <= 1'b0;
      grant <= 4'b0000;
    end else begin
      // Pipeline control signals
      fifo_read_valid_stage2 <= fifo_read_valid_stage1;
      fifo_data_stage2 <= fifo_data_stage1;
      new_req_stage2 <= new_req_stage1;
      
      // Generate grant output
      if (fifo_read_valid_stage2) begin
        grant <= fifo_data_stage2;
      end else begin
        grant <= 4'b0000;
      end
    end
  end
endmodule