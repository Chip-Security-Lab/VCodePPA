module time_sliced_arbiter #(parameter REQ_WIDTH=4, TIME_SLOTS=3) (
  input wire clk, rstn,
  input wire [REQ_WIDTH-1:0] req_i,
  output reg [REQ_WIDTH-1:0] gnt_o
);
  reg [$clog2(TIME_SLOTS)-1:0] slot_cnt;
  reg [REQ_WIDTH-1:0] req_r;
  
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt <= 0;
      req_r <= 0;
      gnt_o <= 0;
    end else begin
      req_r <= req_i;
      if (slot_cnt >= TIME_SLOTS-1) slot_cnt <= 0;
      else slot_cnt <= slot_cnt + 1;
      
      gnt_o <= 0;
      case (slot_cnt)
        0: if (req_r[0]) gnt_o[0] <= 1'b1;
        1: if (req_r[1]) gnt_o[1] <= 1'b1;
        2: if (req_r[2]) gnt_o[2] <= 1'b1;
        default: if (req_r[3]) gnt_o[3] <= 1'b1;
      endcase
    end
  end
endmodule