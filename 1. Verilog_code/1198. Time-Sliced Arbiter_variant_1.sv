//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: time_sliced_arbiter_top.v
// Description: Time-sliced arbiter top module with hierarchical structure
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

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

  // Slot counter module instantiation
  slot_counter #(
    .TIME_SLOTS(TIME_SLOTS)
  ) u_slot_counter (
    .clk       (clk),
    .rstn      (rstn),
    .slot_cnt  (slot_cnt)
  );

  // Request register module instantiation
  request_register #(
    .REQ_WIDTH(REQ_WIDTH)
  ) u_request_register (
    .clk      (clk),
    .rstn     (rstn),
    .req_i    (req_i),
    .req_r    (req_r)
  );

  // Grant generator module instantiation
  grant_generator #(
    .REQ_WIDTH(REQ_WIDTH),
    .TIME_SLOTS(TIME_SLOTS)
  ) u_grant_generator (
    .clk       (clk),
    .rstn      (rstn),
    .slot_cnt  (slot_cnt),
    .req_r     (req_r),
    .gnt_o     (gnt_o)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Slot Counter Module - Controls the time slicing sequence
///////////////////////////////////////////////////////////////////////////////

module slot_counter #(
  parameter TIME_SLOTS = 3
)(
  input  wire clk,
  input  wire rstn,
  output reg [$clog2(TIME_SLOTS)-1:0] slot_cnt
);

  localparam COUNTER_WIDTH = $clog2(TIME_SLOTS);
  localparam MAX_COUNT = TIME_SLOTS - 1;
  
  // Reset logic separated
  always @(negedge rstn) begin
    if (!rstn) begin
      slot_cnt <= {COUNTER_WIDTH{1'b0}};
    end
  end
  
  // Counter logic in dedicated always block
  always @(posedge clk) begin
    if (rstn) begin
      slot_cnt <= (slot_cnt == MAX_COUNT) ? {COUNTER_WIDTH{1'b0}} : slot_cnt + 1'b1;
    end
  end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Request Register Module - Registers incoming requests
///////////////////////////////////////////////////////////////////////////////

module request_register #(
  parameter REQ_WIDTH = 4
)(
  input  wire clk,
  input  wire rstn,
  input  wire [REQ_WIDTH-1:0] req_i,
  output reg  [REQ_WIDTH-1:0] req_r
);

  // Reset logic separated
  always @(negedge rstn) begin
    if (!rstn) begin
      req_r <= {REQ_WIDTH{1'b0}};
    end
  end
  
  // Request registration logic in dedicated always block
  always @(posedge clk) begin
    if (rstn) begin
      req_r <= req_i;
    end
  end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Grant Generator Module - Generates grant signals based on time slots
///////////////////////////////////////////////////////////////////////////////

module grant_generator #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
)(
  input  wire clk,
  input  wire rstn,
  input  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt,
  input  wire [REQ_WIDTH-1:0] req_r,
  output reg  [REQ_WIDTH-1:0] gnt_o
);

  // Slot mask generation - separated as combinational logic
  reg [REQ_WIDTH-1:0] slot_mask;
  
  // Generate slot mask based on current time slot
  always @(*) begin
    integer i;
    slot_mask = {REQ_WIDTH{1'b0}};
    for (i = 0; i < REQ_WIDTH; i = i + 1) begin
      if (i < TIME_SLOTS) begin
        slot_mask[i] = (slot_cnt == i);
      end else begin
        slot_mask[i] = (slot_cnt >= TIME_SLOTS);
      end
    end
  end

  // Reset logic for grant outputs
  always @(negedge rstn) begin
    if (!rstn) begin
      gnt_o <= {REQ_WIDTH{1'b0}};
    end
  end
  
  // Grant calculation separated into dedicated always block
  always @(posedge clk) begin
    if (rstn) begin
      gnt_o <= req_r & slot_mask;
    end
  end

endmodule