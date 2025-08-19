//SystemVerilog
//IEEE 1364-2005 Verilog
module fifo_arbiter(
  input wire clk,
  input wire rst_n,
  input wire [3:0] request,
  input wire new_req,
  output reg [3:0] grant,
  output wire empty
);
  // FIFO storage
  reg [3:0] fifo [0:3];
  reg [1:0] wr_ptr, rd_ptr;
  
  // Pipeline registers for request processing
  reg new_req_stage1, new_req_stage2;
  reg [3:0] request_stage1, request_stage2;
  reg [1:0] wr_ptr_stage1, wr_ptr_stage2;
  
  // Pipeline registers for grant processing
  reg read_valid_stage1, read_valid_stage2;
  reg [3:0] read_data_stage1, read_data_stage2;
  reg [1:0] rd_ptr_stage1, rd_ptr_stage2;
  
  // Status signals
  wire fifo_empty;
  assign fifo_empty = (wr_ptr == rd_ptr);
  assign empty = fifo_empty;
  
  // Stage 1: Input registration and request handling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_req_stage1 <= 1'b0;
      request_stage1 <= 4'b0;
      wr_ptr_stage1 <= 2'b0;
      read_valid_stage1 <= 1'b0;
      rd_ptr_stage1 <= 2'b0;
    end else begin
      // Register input signals
      new_req_stage1 <= new_req;
      request_stage1 <= request;
      wr_ptr_stage1 <= wr_ptr;
      
      // Register read control signals
      read_valid_stage1 <= !fifo_empty;
      rd_ptr_stage1 <= rd_ptr;
    end
  end
  
  // Stage 2: FIFO write/read operations
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 2'b0;
      rd_ptr <= 2'b0;
      new_req_stage2 <= 1'b0;
      request_stage2 <= 4'b0;
      wr_ptr_stage2 <= 2'b0;
      read_valid_stage2 <= 1'b0;
      read_data_stage1 <= 4'b0;
      rd_ptr_stage2 <= 2'b0;
    end else begin
      // Pass along pipeline signals
      new_req_stage2 <= new_req_stage1;
      request_stage2 <= request_stage1;
      wr_ptr_stage2 <= wr_ptr_stage1;
      read_valid_stage2 <= read_valid_stage1;
      rd_ptr_stage2 <= rd_ptr_stage1;
      
      // FIFO write operation
      if (new_req_stage1) begin
        fifo[wr_ptr_stage1] <= request_stage1;
        wr_ptr <= kogge_stone_adder_2bit(wr_ptr_stage1, 2'b01);
      end
      
      // FIFO read operation
      if (read_valid_stage1) begin
        read_data_stage1 <= fifo[rd_ptr_stage1];
        rd_ptr <= kogge_stone_adder_2bit(rd_ptr_stage1, 2'b01);
      end else begin
        read_data_stage1 <= 4'b0;
      end
    end
  end
  
  // Stage 3: Output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 4'b0;
      read_data_stage2 <= 4'b0;
    end else begin
      read_data_stage2 <= read_data_stage1;
      
      // Generate grant output
      if (read_valid_stage2) begin
        grant <= read_data_stage2;
      end else begin
        grant <= 4'b0;
      end
    end
  end
  
  // Kogge-Stone 2-bit adder function
  function [1:0] kogge_stone_adder_2bit;
    input [1:0] a;
    input [1:0] b;
    
    reg [1:0] p; // Propagate signals
    reg [1:0] g; // Generate signals
    reg [1:0] c; // Carry signals
    reg [1:0] sum; // Sum output
    
    begin
      // Step 1: Generate propagate and generate signals
      p[0] = a[0] ^ b[0];
      p[1] = a[1] ^ b[1];
      g[0] = a[0] & b[0];
      g[1] = a[1] & b[1];
      
      // Step 2: Compute carries
      c[0] = g[0];
      c[1] = g[1] | (p[1] & g[0]);
      
      // Step 3: Compute sum
      sum[0] = p[0];
      sum[1] = p[1] ^ c[0];
      
      kogge_stone_adder_2bit = sum;
    end
  endfunction
  
endmodule