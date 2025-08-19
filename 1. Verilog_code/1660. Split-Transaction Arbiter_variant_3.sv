//SystemVerilog
module split_transaction_arbiter(
  input clk, reset_n,
  input [7:0] req_addr, req_data,
  input [3:0] req_valid,
  output reg [3:0] grant_addr, grant_data
);

  reg [3:0] addr_phase_active;
  reg [3:0] data_phase_queue;
  reg [3:0] next_addr_phase;
  reg [3:0] next_data_phase;
  reg [3:0] next_grant_addr;
  reg [3:0] next_grant_data;
  
  // Address phase arbitration logic
  always @(*) begin
    next_addr_phase = addr_phase_active;
    next_grant_addr = 4'b0;
    
    casex({addr_phase_active, req_valid})
      8'b0000_????: begin
        next_addr_phase[0] = req_valid[0];
        next_grant_addr[0] = req_valid[0];
      end
      8'b0001_????: begin
        next_addr_phase[1] = req_valid[1];
        next_grant_addr[1] = req_valid[1];
      end
      8'b0011_????: begin
        next_addr_phase[2] = req_valid[2];
        next_grant_addr[2] = req_valid[2];
      end
      8'b0111_????: begin
        next_addr_phase[3] = req_valid[3];
        next_grant_addr[3] = req_valid[3];
      end
      default: begin
        next_addr_phase = addr_phase_active;
        next_grant_addr = 4'b0;
      end
    endcase
  end
  
  // Data phase arbitration logic
  always @(*) begin
    next_data_phase = data_phase_queue;
    next_grant_data = 4'b0;
    
    casex(data_phase_queue)
      4'b0001: begin
        next_data_phase[0] = 1'b0;
        next_grant_data[0] = 1'b1;
      end
      4'b0010: begin
        next_data_phase[1] = 1'b0;
        next_grant_data[1] = 1'b1;
      end
      4'b0100: begin
        next_data_phase[2] = 1'b0;
        next_grant_data[2] = 1'b1;
      end
      4'b1000: begin
        next_data_phase[3] = 1'b0;
        next_grant_data[3] = 1'b1;
      end
      default: begin
        next_data_phase = data_phase_queue;
        next_grant_data = 4'b0;
      end
    endcase
  end
  
  // Sequential logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_phase_active <= 4'b0;
      data_phase_queue <= 4'b0;
      grant_addr <= 4'b0;
      grant_data <= 4'b0;
    end else begin
      addr_phase_active <= next_addr_phase;
      data_phase_queue <= next_data_phase;
      grant_addr <= next_grant_addr;
      grant_data <= next_grant_data;
    end
  end
  
endmodule