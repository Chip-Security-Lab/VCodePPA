//SystemVerilog
module split_transaction_arbiter(
  input clk, reset_n,
  input [7:0] req_addr, req_data,
  input [3:0] req_req,
  output reg [3:0] req_ack,
  output reg [3:0] grant_addr, grant_data
);
  reg [3:0] addr_phase_active;
  reg [3:0] data_phase_queue;
  reg [3:0] addr_phase_active_buf;
  reg [3:0] data_phase_queue_buf;
  reg [3:0] grant_addr_buf;
  reg [3:0] grant_data_buf;
  reg [3:0] req_ack_buf;
  
  // Reset logic for all registers
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_phase_active <= 4'b0;
      data_phase_queue <= 4'b0;
      addr_phase_active_buf <= 4'b0;
      data_phase_queue_buf <= 4'b0;
      grant_addr_buf <= 4'b0;
      grant_data_buf <= 4'b0;
      grant_addr <= 4'b0;
      grant_data <= 4'b0;
      req_ack <= 4'b0;
      req_ack_buf <= 4'b0;
    end
  end
  
  // First stage: Calculate arbitration results
  always @(posedge clk) begin
    if (reset_n) begin
      addr_phase_active <= req_req & ~data_phase_queue;
      data_phase_queue <= addr_phase_active;
      req_ack <= req_req & ~data_phase_queue;
    end
  end
  
  // Second stage: Buffer high fanout signals
  always @(posedge clk) begin
    if (reset_n) begin
      addr_phase_active_buf <= addr_phase_active;
      data_phase_queue_buf <= data_phase_queue;
      req_ack_buf <= req_ack;
    end
  end
  
  // Third stage: Generate intermediate grants
  always @(posedge clk) begin
    if (reset_n) begin
      grant_addr_buf <= addr_phase_active_buf;
      grant_data_buf <= data_phase_queue_buf;
    end
  end
  
  // Final stage: Output registers
  always @(posedge clk) begin
    if (reset_n) begin
      grant_addr <= grant_addr_buf;
      grant_data <= grant_data_buf;
    end
  end
endmodule