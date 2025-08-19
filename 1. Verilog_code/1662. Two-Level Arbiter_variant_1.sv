//SystemVerilog
module two_level_arbiter(
  input clock, reset,
  input [1:0] group_sel,
  input [7:0] requests,
  output reg [7:0] grants
);

  // Buffered input signals
  reg [7:0] req_buf;
  reg [1:0] group_sel_buf;
  
  // Buffered intermediate signals
  reg [1:0] group_reqs;
  reg [1:0] group_grants;
  reg [3:0] group0_prio;
  reg [3:0] group1_prio;
  
  // Input buffering
  always @(posedge clock) begin
    if (reset) begin
      req_buf <= 8'b0;
      group_sel_buf <= 2'b0;
    end else begin
      req_buf <= requests;
      group_sel_buf <= group_sel;
    end
  end

  // Group request detection with buffering
  always @(posedge clock) begin
    if (reset) begin
      group_reqs <= 2'b0;
    end else begin
      group_reqs[0] <= req_buf[0] | req_buf[1] | req_buf[2] | req_buf[3];
      group_reqs[1] <= req_buf[4] | req_buf[5] | req_buf[6] | req_buf[7];
    end
  end

  // Priority encoding with buffering
  always @(posedge clock) begin
    if (reset) begin
      group0_prio <= 4'b0;
      group1_prio <= 4'b0;
    end else begin
      group0_prio[0] <= req_buf[0];
      group0_prio[1] <= req_buf[1] & ~req_buf[0];
      group0_prio[2] <= req_buf[2] & ~(|req_buf[1:0]);
      group0_prio[3] <= req_buf[3] & ~(|req_buf[2:0]);
      
      group1_prio[0] <= req_buf[4];
      group1_prio[1] <= req_buf[5] & ~req_buf[4];
      group1_prio[2] <= req_buf[6] & ~(|req_buf[5:4]);
      group1_prio[3] <= req_buf[7] & ~(|req_buf[6:4]);
    end
  end

  // Group arbitration with buffering
  always @(posedge clock) begin
    if (reset) begin
      group_grants <= 2'b0;
    end else begin
      group_grants[0] <= group_reqs[0] & (group_sel_buf[0] | ~group_reqs[1]);
      group_grants[1] <= group_reqs[1] & (group_sel_buf[1] | ~group_reqs[0]);
    end
  end

  // Final grant generation
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
    end else begin
      grants <= 8'b0;
      if (group_grants[0]) begin
        case (1'b1)
          group0_prio[0]: grants[0] <= 1'b1;
          group0_prio[1]: grants[1] <= 1'b1;
          group0_prio[2]: grants[2] <= 1'b1;
          group0_prio[3]: grants[3] <= 1'b1;
        endcase
      end
      if (group_grants[1]) begin
        case (1'b1)
          group1_prio[0]: grants[4] <= 1'b1;
          group1_prio[1]: grants[5] <= 1'b1;
          group1_prio[2]: grants[6] <= 1'b1;
          group1_prio[3]: grants[7] <= 1'b1;
        endcase
      end
    end
  end

endmodule