//SystemVerilog
// Top-level module - Time Sliced Arbiter
module time_sliced_arbiter #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
) (
  input  wire                 clk,
  input  wire                 rstn,
  input  wire [REQ_WIDTH-1:0] req_i,
  output wire [REQ_WIDTH-1:0] gnt_o
);

  // Internal signals for stage connections
  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt_stage1;
  wire [REQ_WIDTH-1:0]          req_stage1;
  wire                          valid_stage1;
  
  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt_stage2;
  wire [REQ_WIDTH-1:0]          req_stage2;
  wire                          valid_stage2;
  
  wire [$clog2(TIME_SLOTS)-1:0] slot_cnt_stage2_5;
  wire [REQ_WIDTH-1:0]          req_stage2_5;
  wire                          valid_stage2_5;
  wire [REQ_WIDTH-1:0]          pre_gnt;
  
  wire [REQ_WIDTH-1:0]          gnt_stage3;
  wire                          valid_stage3;
  
  wire [REQ_WIDTH-1:0]          gnt_buffer;
  wire                          valid_buffer;

  // Instantiate pipeline stages
  slot_counter_stage #(
    .TIME_SLOTS(TIME_SLOTS)
  ) stage1 (
    .clk            (clk),
    .rstn           (rstn),
    .req_i          (req_i),
    .slot_cnt_o     (slot_cnt_stage1),
    .req_o          (req_stage1),
    .valid_o        (valid_stage1)
  );

  request_processing_stage #(
    .REQ_WIDTH(REQ_WIDTH),
    .TIME_SLOTS(TIME_SLOTS)
  ) stage2 (
    .clk            (clk),
    .rstn           (rstn),
    .slot_cnt_i     (slot_cnt_stage1),
    .req_i          (req_stage1),
    .valid_i        (valid_stage1),
    .slot_cnt_o     (slot_cnt_stage2),
    .req_o          (req_stage2),
    .valid_o        (valid_stage2)
  );

  grant_preparation_stage #(
    .REQ_WIDTH(REQ_WIDTH),
    .TIME_SLOTS(TIME_SLOTS)
  ) stage2_5 (
    .clk            (clk),
    .rstn           (rstn),
    .slot_cnt_i     (slot_cnt_stage2),
    .req_i          (req_stage2),
    .valid_i        (valid_stage2),
    .slot_cnt_o     (slot_cnt_stage2_5),
    .req_o          (req_stage2_5),
    .valid_o        (valid_stage2_5),
    .pre_gnt_o      (pre_gnt)
  );

  grant_generation_stage #(
    .REQ_WIDTH(REQ_WIDTH)
  ) stage3 (
    .clk            (clk),
    .rstn           (rstn),
    .pre_gnt_i      (pre_gnt),
    .valid_i        (valid_stage2_5),
    .gnt_o          (gnt_stage3),
    .valid_o        (valid_stage3)
  );

  output_buffer_stage #(
    .REQ_WIDTH(REQ_WIDTH)
  ) output_stage (
    .clk            (clk),
    .rstn           (rstn),
    .gnt_i          (gnt_stage3),
    .valid_i        (valid_stage3),
    .gnt_buffer_o   (gnt_buffer),
    .valid_buffer_o (valid_buffer),
    .gnt_o          (gnt_o)
  );

endmodule

// Stage 1: Request registration and slot counter management
module slot_counter_stage #(
  parameter TIME_SLOTS = 3
) (
  input  wire                           clk,
  input  wire                           rstn,
  input  wire [REQ_WIDTH-1:0]           req_i,
  output reg  [$clog2(TIME_SLOTS)-1:0]  slot_cnt_o,
  output reg  [REQ_WIDTH-1:0]           req_o,
  output reg                            valid_o
);

  parameter REQ_WIDTH = 4; // Internal parameter needed for req_i/req_o

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt_o <= 0;
      req_o <= 0;
      valid_o <= 0;
    end else begin
      req_o <= req_i;
      valid_o <= 1'b1;
      
      if (slot_cnt_o >= TIME_SLOTS-1) 
        slot_cnt_o <= 0;
      else 
        slot_cnt_o <= slot_cnt_o + 1;
    end
  end
endmodule

// Stage 2: Request processing based on time slot
module request_processing_stage #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
) (
  input  wire                           clk,
  input  wire                           rstn,
  input  wire [$clog2(TIME_SLOTS)-1:0]  slot_cnt_i,
  input  wire [REQ_WIDTH-1:0]           req_i,
  input  wire                           valid_i,
  output reg  [$clog2(TIME_SLOTS)-1:0]  slot_cnt_o,
  output reg  [REQ_WIDTH-1:0]           req_o,
  output reg                            valid_o
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt_o <= 0;
      req_o <= 0;
      valid_o <= 0;
    end else begin
      slot_cnt_o <= slot_cnt_i;
      req_o <= req_i;
      valid_o <= valid_i;
    end
  end
endmodule

// Stage 2.5: Critical path splitting for grant preparation
module grant_preparation_stage #(
  parameter REQ_WIDTH = 4,
  parameter TIME_SLOTS = 3
) (
  input  wire                           clk,
  input  wire                           rstn,
  input  wire [$clog2(TIME_SLOTS)-1:0]  slot_cnt_i,
  input  wire [REQ_WIDTH-1:0]           req_i,
  input  wire                           valid_i,
  output reg  [$clog2(TIME_SLOTS)-1:0]  slot_cnt_o,
  output reg  [REQ_WIDTH-1:0]           req_o,
  output reg                            valid_o,
  output reg  [REQ_WIDTH-1:0]           pre_gnt_o
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      slot_cnt_o <= 0;
      req_o <= 0;
      valid_o <= 0;
      pre_gnt_o <= 0;
    end else begin
      slot_cnt_o <= slot_cnt_i;
      req_o <= req_i;
      valid_o <= valid_i;
      
      // Pre-computation of grant signals to split combinational path
      pre_gnt_o <= 0; // Default all grants to 0
      if (valid_i) begin
        case (slot_cnt_i)
          0: if (req_i[0]) pre_gnt_o[0] <= 1'b1;
          1: if (req_i[1]) pre_gnt_o[1] <= 1'b1;
          2: if (req_i[2]) pre_gnt_o[2] <= 1'b1;
          default: if (req_i[3]) pre_gnt_o[3] <= 1'b1;
        endcase
      end
    end
  end
endmodule

// Stage 3: Grant generation (now simplified with pre-computation)
module grant_generation_stage #(
  parameter REQ_WIDTH = 4
) (
  input  wire                 clk,
  input  wire                 rstn,
  input  wire [REQ_WIDTH-1:0] pre_gnt_i,
  input  wire                 valid_i,
  output reg  [REQ_WIDTH-1:0] gnt_o,
  output reg                  valid_o
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      gnt_o <= 0;
      valid_o <= 0;
    end else begin
      valid_o <= valid_i;
      gnt_o <= pre_gnt_i; // Use pre-computed grant signals
    end
  end
endmodule

// Output buffer stage to improve timing
module output_buffer_stage #(
  parameter REQ_WIDTH = 4
) (
  input  wire                 clk,
  input  wire                 rstn,
  input  wire [REQ_WIDTH-1:0] gnt_i,
  input  wire                 valid_i,
  output reg  [REQ_WIDTH-1:0] gnt_buffer_o,
  output reg                  valid_buffer_o,
  output reg  [REQ_WIDTH-1:0] gnt_o
);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      gnt_buffer_o <= 0;
      valid_buffer_o <= 0;
    end else begin
      valid_buffer_o <= valid_i;
      gnt_buffer_o <= gnt_i;
    end
  end
  
  // Final output assignment
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      gnt_o <= 0;
    end else begin
      if (valid_buffer_o)
        gnt_o <= gnt_buffer_o;
      else
        gnt_o <= 0;
    end
  end
endmodule