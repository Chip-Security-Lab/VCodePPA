//SystemVerilog
module look_ahead_arbiter #(parameter REQS=4) (
  input wire clk, rst_n,
  input wire [REQS-1:0] req,
  input wire [REQS-1:0] predicted_req,
  output reg [REQS-1:0] grant
);
  // Main signals
  reg [REQS-1:0] next_req, next_req_buf1, next_req_buf2;
  reg [1:0] current_priority, current_priority_buf1, current_priority_buf2;
  reg [REQS-1:0] req_reg, req_reg_buf1, req_reg_buf2;
  reg [2:0] grant_sel;
  reg grant_valid, grant_valid_buf1, grant_valid_buf2;
  
  // Input registration with buffers for high fanout signals
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_reg <= 0;
      next_req <= 0;
    end else begin
      req_reg <= req;
      next_req <= predicted_req;
    end
  end
  
  // Buffer registers for high fanout signals
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset buffer registers
      req_reg_buf1 <= 0;
      req_reg_buf2 <= 0;
      next_req_buf1 <= 0;
      next_req_buf2 <= 0;
      current_priority_buf1 <= 0;
      current_priority_buf2 <= 0;
    end else begin
      // Update buffer registers
      req_reg_buf1 <= req_reg;
      req_reg_buf2 <= req_reg;
      next_req_buf1 <= next_req;
      next_req_buf2 <= next_req;
      current_priority_buf1 <= current_priority;
      current_priority_buf2 <= current_priority;
    end
  end

  // Grant validation combinational logic
  always @(*) begin
    grant_valid = 1'b0;
    grant_sel = 3'b000;
    
    if (req_reg_buf1[current_priority_buf1]) begin
      grant_valid = 1'b1;
      grant_sel = {1'b0, current_priority_buf1};
    end
    else if (|req_reg_buf1) begin
      if (req_reg_buf1[0] && current_priority_buf1 != 0) begin
        grant_valid = 1'b1;
        grant_sel = 3'b000;
      end
      else if (req_reg_buf1[1] && current_priority_buf1 != 1) begin
        grant_valid = 1'b1;
        grant_sel = 3'b001;
      end
      else if (req_reg_buf1[2] && current_priority_buf1 != 2) begin
        grant_valid = 1'b1;
        grant_sel = 3'b010;
      end
      else if (req_reg_buf1[3] && current_priority_buf1 != 3) begin
        grant_valid = 1'b1;
        grant_sel = 3'b011;
      end
    end
  end
  
  // Buffer register for grant_valid to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_valid_buf1 <= 1'b0;
      grant_valid_buf2 <= 1'b0;
    end else begin
      grant_valid_buf1 <= grant_valid;
      grant_valid_buf2 <= grant_valid;
    end
  end
  
  // Output registers and priority update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 0;
      current_priority <= 0;
    end else begin
      grant <= 0;
      
      if (grant_valid_buf1) begin
        grant[grant_sel[1:0]] <= 1'b1;
      end
      
      // Look ahead for next priority using buffered signals
      if (|next_req_buf2) begin
        if (next_req_buf2[0]) current_priority <= 0;
        else if (next_req_buf2[1]) current_priority <= 1;
        else if (next_req_buf2[2]) current_priority <= 2;
        else current_priority <= 3;
      end
    end
  end
endmodule