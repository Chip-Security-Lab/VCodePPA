//SystemVerilog
module split_transaction_arbiter(
  input clk, reset_n,
  input [7:0] req_addr, req_data,
  input [3:0] req_req,
  output reg [3:0] grant_addr, grant_data,
  output reg [3:0] req_ack
);
  reg [3:0] addr_phase_active;
  reg [3:0] data_phase_queue;
  reg [3:0] req_pending;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_phase_active <= 4'b0;
      data_phase_queue <= 4'b0;
      grant_addr <= 4'b0;
      grant_data <= 4'b0;
      req_ack <= 4'b0;
      req_pending <= 4'b0;
    end else begin
      // Split transaction arbitration logic
      // Address phase arbitration
      addr_phase_active <= (req_req & ~req_ack) ? req_req & ~req_ack : 
                          (addr_phase_active & ~data_phase_queue) ? addr_phase_active : 4'b0;
      
      // Data phase arbitration
      data_phase_queue <= (addr_phase_active & ~data_phase_queue) ? addr_phase_active : 
                         (data_phase_queue & ~req_ack) ? data_phase_queue : 4'b0;
      
      // Grant signals
      grant_addr <= (req_req & ~req_ack) ? req_addr : 
                   (addr_phase_active & ~data_phase_queue) ? grant_addr : 8'b0;
      
      grant_data <= (data_phase_queue & ~req_ack) ? req_data : 
                   (data_phase_queue & ~req_ack) ? grant_data : 8'b0;
      
      // Request-acknowledge handshake
      req_ack <= req_pending;
      req_pending <= req_req & ~req_ack;
    end
  end
endmodule