//SystemVerilog
module time_sliced_arbiter #(parameter REQ_WIDTH=4, TIME_SLOTS=3) (
  input wire clk, rstn,
  input wire [REQ_WIDTH-1:0] req_i,
  output reg [REQ_WIDTH-1:0] gnt_o
);
  reg [$clog2(TIME_SLOTS)-1:0] slot_cnt;
  reg [REQ_WIDTH-1:0] req_r;
  reg [REQ_WIDTH-1:0] next_gnt;
  
  // Pre-compute next slot counter to reduce path delay
  reg [$clog2(TIME_SLOTS)-1:0] next_slot_cnt;
  
  // Pre-decode slot selection logic to reduce critical path
  reg [TIME_SLOTS-1:0] slot_sel;
  
  // Calculate next slot counter
  always @(*) begin
    if (slot_cnt >= TIME_SLOTS-1) begin
      next_slot_cnt = 0;
    end else begin
      next_slot_cnt = slot_cnt + 1'b1;
    end
  end
  
  // Generate slot selection signal
  always @(*) begin
    slot_sel = 0;
    if (slot_cnt == 0) begin
      slot_sel[0] = 1'b1;
    end else if (slot_cnt == 1) begin
      slot_sel[1] = 1'b1;
    end else if (slot_cnt == 2) begin
      slot_sel[2] = 1'b1;
    end
  end
  
  // Calculate next grant outputs based on requests and slot selection
  always @(*) begin
    next_gnt = 0;
    if (slot_sel[0] && req_r[0]) begin
      next_gnt[0] = 1'b1;
    end else if (slot_sel[1] && req_r[1]) begin
      next_gnt[1] = 1'b1;
    end else if (slot_sel[2] && req_r[2]) begin
      next_gnt[2] = 1'b1;
    end else if (req_r[3]) begin
      next_gnt[3] = 1'b1;
    end
  end
  
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt <= 0;
      req_r <= 0;
      gnt_o <= 0;
    end else begin
      req_r <= req_i;
      slot_cnt <= next_slot_cnt;
      gnt_o <= next_gnt;
    end
  end
endmodule