//SystemVerilog
//===================================================================
// Time-Sliced Arbiter Top Module with Hierarchical Structure
//===================================================================
module time_sliced_arbiter #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
)(
  input  wire clk,
  input  wire rstn,
  input  wire [REQ_WIDTH-1:0] req_i,
  output wire [REQ_WIDTH-1:0] gnt_o
);

  // Internal signals
  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt;
  wire [REQ_WIDTH-1:0] req_r;

  // Request synchronizer submodule
  request_synchronizer #(
    .REQ_WIDTH(REQ_WIDTH)
  ) req_sync_inst (
    .clk   (clk),
    .rstn  (rstn),
    .req_i (req_i),
    .req_r (req_r)
  );

  // Slot counter submodule
  slot_counter #(
    .TIME_SLOTS(TIME_SLOTS)
  ) slot_cnt_inst (
    .clk      (clk),
    .rstn     (rstn),
    .slot_cnt (slot_cnt)
  );

  // Grant generator submodule
  grant_generator #(
    .REQ_WIDTH(REQ_WIDTH),
    .TIME_SLOTS(TIME_SLOTS)
  ) grant_gen_inst (
    .clk      (clk),
    .rstn     (rstn),
    .req_r    (req_r),
    .slot_cnt (slot_cnt),
    .gnt_o    (gnt_o)
  );

endmodule

//===================================================================
// Request Synchronizer Module
//===================================================================
module request_synchronizer #(
  parameter REQ_WIDTH = 4
)(
  input  wire clk,
  input  wire rstn,
  input  wire [REQ_WIDTH-1:0] req_i,
  output reg  [REQ_WIDTH-1:0] req_r
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      req_r <= {REQ_WIDTH{1'b0}};
    end else begin
      req_r <= req_i;
    end
  end

endmodule

//===================================================================
// Slot Counter Module
//===================================================================
module slot_counter #(
  parameter TIME_SLOTS = 3
)(
  input  wire clk,
  input  wire rstn,
  output reg  [$clog2(TIME_SLOTS)-1:0] slot_cnt
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt <= {$clog2(TIME_SLOTS){1'b0}};
    end else begin
      if (slot_cnt >= TIME_SLOTS-1) 
        slot_cnt <= {$clog2(TIME_SLOTS){1'b0}};
      else 
        slot_cnt <= slot_cnt + 1'b1;
    end
  end

endmodule

//===================================================================
// Grant Generator Module
//===================================================================
module grant_generator #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
)(
  input  wire clk,
  input  wire rstn,
  input  wire [REQ_WIDTH-1:0] req_r,
  input  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt,
  output reg  [REQ_WIDTH-1:0] gnt_o
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      gnt_o <= {REQ_WIDTH{1'b0}};
    end else begin
      gnt_o <= {REQ_WIDTH{1'b0}};
      
      case (slot_cnt)
        0: if (req_r[0]) gnt_o[0] <= 1'b1;
        1: if (req_r[1]) gnt_o[1] <= 1'b1;
        2: if (req_r[2]) gnt_o[2] <= 1'b1;
        default: if (req_r[3]) gnt_o[3] <= 1'b1;
      endcase
    end
  end

endmodule