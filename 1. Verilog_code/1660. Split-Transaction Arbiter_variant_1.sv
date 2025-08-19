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
  wire [3:0] addr_phase_priority;
  wire [3:0] data_phase_priority;
  
  // Priority encoder for address phase
  assign addr_phase_priority[0] = req_req[0] & ~addr_phase_active[0];
  assign addr_phase_priority[1] = req_req[1] & ~addr_phase_active[1] & ~req_req[0];
  assign addr_phase_priority[2] = req_req[2] & ~addr_phase_active[2] & ~(|req_req[1:0]);
  assign addr_phase_priority[3] = req_req[3] & ~addr_phase_active[3] & ~(|req_req[2:0]);
  
  // Priority encoder for data phase
  assign data_phase_priority[0] = data_phase_queue[0];
  assign data_phase_priority[1] = data_phase_queue[1] & ~data_phase_queue[0];
  assign data_phase_priority[2] = data_phase_queue[2] & ~(|data_phase_queue[1:0]);
  assign data_phase_priority[3] = data_phase_queue[3] & ~(|data_phase_queue[2:0]);
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_phase_active <= 4'b0;
      data_phase_queue <= 4'b0;
      grant_addr <= 4'b0;
      grant_data <= 4'b0;
      req_ack <= 4'b0;
    end else begin
      // Address phase arbitration
      grant_addr <= addr_phase_priority;
      
      // Update address phase active status
      addr_phase_active <= (addr_phase_active | addr_phase_priority) & ~data_phase_priority;
      
      // Update data phase queue
      data_phase_queue <= (data_phase_queue | addr_phase_priority) & ~data_phase_priority;
      
      // Data phase arbitration
      grant_data <= data_phase_priority;
      
      // Generate ack signals
      req_ack <= addr_phase_priority;
    end
  end
endmodule