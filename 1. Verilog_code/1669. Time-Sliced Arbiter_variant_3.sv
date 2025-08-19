//SystemVerilog
module time_sliced_arbiter_req_ack(
  input clk, rst_n,
  input [3:0] req_in,
  output reg [3:0] ack_out,
  output reg [3:0] gnt,
  output reg busy
);

  // Pipeline stage 1: Counter and request sampling
  reg [1:0] time_slice_counter_stage1;
  reg [3:0] req_stage1;
  reg [3:0] ack_stage1;
  
  // Pipeline stage 2: Grant generation
  reg [1:0] time_slice_counter_stage2;
  reg [3:0] gnt_stage2;
  reg [3:0] ack_stage2;
  
  // Pipeline stage 3: Output and busy generation
  reg [3:0] gnt_stage3;
  reg busy_stage3;
  reg [3:0] ack_stage3;

  // Stage 1: Counter update
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter_stage1 <= 2'b00;
    end else begin
      time_slice_counter_stage1 <= time_slice_counter_stage1 + 1'b1;
    end
  end

  // Stage 1: Request sampling and acknowledgment
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      req_stage1 <= 4'b0000;
      ack_stage1 <= 4'b0000;
    end else begin
      req_stage1 <= req_in;
      ack_stage1 <= ack_out;
    end
  end

  // Stage 2: Counter propagation
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter_stage2 <= 2'b00;
    end else begin
      time_slice_counter_stage2 <= time_slice_counter_stage1;
    end
  end

  // Stage 2: Grant generation for port 0
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt_stage2[0] <= 1'b0;
    end else if (req_stage1[0] && !ack_stage1[0] && time_slice_counter_stage1 == 2'b00) begin
      gnt_stage2[0] <= 1'b1;
    end else begin
      gnt_stage2[0] <= 1'b0;
    end
  end

  // Stage 2: Grant generation for port 1
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt_stage2[1] <= 1'b0;
    end else if (req_stage1[1] && !ack_stage1[1] && time_slice_counter_stage1 == 2'b01) begin
      gnt_stage2[1] <= 1'b1;
    end else begin
      gnt_stage2[1] <= 1'b0;
    end
  end

  // Stage 2: Grant generation for port 2
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt_stage2[2] <= 1'b0;
    end else if (req_stage1[2] && !ack_stage1[2] && time_slice_counter_stage1 == 2'b10) begin
      gnt_stage2[2] <= 1'b1;
    end else begin
      gnt_stage2[2] <= 1'b0;
    end
  end

  // Stage 2: Grant generation for port 3
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt_stage2[3] <= 1'b0;
    end else if (req_stage1[3] && !ack_stage1[3] && time_slice_counter_stage1 == 2'b11) begin
      gnt_stage2[3] <= 1'b1;
    end else begin
      gnt_stage2[3] <= 1'b0;
    end
  end

  // Stage 2: Acknowledgment propagation
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ack_stage2 <= 4'b0000;
    end else begin
      ack_stage2 <= ack_stage1;
    end
  end

  // Stage 3: Grant propagation
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt_stage3 <= 4'b0000;
    end else begin
      gnt_stage3 <= gnt_stage2;
    end
  end

  // Stage 3: Busy signal generation
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      busy_stage3 <= 1'b0;
    end else begin
      busy_stage3 <= |gnt_stage2;
    end
  end

  // Stage 3: Acknowledgment propagation
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ack_stage3 <= 4'b0000;
    end else begin
      ack_stage3 <= ack_stage2;
    end
  end

  // Output assignments
  assign gnt = gnt_stage3;
  assign busy = busy_stage3;
  assign ack_out = ack_stage3;

endmodule