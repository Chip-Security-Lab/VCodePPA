//SystemVerilog
module two_level_arbiter(
  input clock, reset,
  input [1:0] group_sel,
  input [7:0] requests,
  output reg [7:0] grants,
  output reg req_valid,
  input ack
);

  // Stage 1: Group request calculation
  reg [1:0] group_reqs_stage1;
  reg [1:0] group_sel_stage1;
  reg [7:0] requests_stage1;
  
  // Stage 2: Group arbitration
  reg [1:0] group_grants_stage2;
  reg [1:0] group_sel_stage2;
  reg [7:0] requests_stage2;
  
  // Stage 3: Final arbitration
  reg [7:0] grants_stage3;
  
  // Pipeline control signals
  reg req_stage1, req_stage2, req_stage3;
  reg ack_stage1, ack_stage2, ack_stage3;
  
  // Stage 1: Calculate group requests
  always @(posedge clock) begin
    if (reset) begin
      group_reqs_stage1 <= 2'b0;
      group_sel_stage1 <= 2'b0;
      requests_stage1 <= 8'b0;
      req_stage1 <= 1'b0;
      ack_stage1 <= 1'b0;
    end else begin
      if (!ack_stage1) begin
        group_reqs_stage1[0] <= |requests[3:0];
        group_reqs_stage1[1] <= |requests[7:4];
        group_sel_stage1 <= group_sel;
        requests_stage1 <= requests;
        req_stage1 <= 1'b1;
      end else if (ack) begin
        req_stage1 <= 1'b0;
        ack_stage1 <= 1'b0;
      end
    end
  end
  
  // Stage 2: Group arbitration
  always @(posedge clock) begin
    if (reset) begin
      group_grants_stage2 <= 2'b0;
      group_sel_stage2 <= 2'b0;
      requests_stage2 <= 8'b0;
      req_stage2 <= 1'b0;
      ack_stage2 <= 1'b0;
    end else begin
      if (req_stage1 && !ack_stage2) begin
        // Group arbitration logic
        case (group_sel_stage1)
          2'b00: group_grants_stage2 <= 2'b01;
          2'b01: group_grants_stage2 <= 2'b10;
          default: group_grants_stage2 <= 2'b00;
        endcase
        group_sel_stage2 <= group_sel_stage1;
        requests_stage2 <= requests_stage1;
        req_stage2 <= 1'b1;
      end else if (ack) begin
        req_stage2 <= 1'b0;
        ack_stage2 <= 1'b0;
      end
    end
  end
  
  // Stage 3: Final arbitration
  always @(posedge clock) begin
    if (reset) begin
      grants_stage3 <= 8'b0;
      req_stage3 <= 1'b0;
      ack_stage3 <= 1'b0;
    end else begin
      if (req_stage2 && !ack_stage3) begin
        grants_stage3 <= 8'b0;
        if (group_grants_stage2[0]) begin
          // Arbitrate within group 0
          case (requests_stage2[3:0])
            4'b0001: grants_stage3[0] <= 1'b1;
            4'b0010: grants_stage3[1] <= 1'b1;
            4'b0100: grants_stage3[2] <= 1'b1;
            4'b1000: grants_stage3[3] <= 1'b1;
            default: grants_stage3 <= 8'b0;
          endcase
        end else if (group_grants_stage2[1]) begin
          // Arbitrate within group 1
          case (requests_stage2[7:4])
            4'b0001: grants_stage3[4] <= 1'b1;
            4'b0010: grants_stage3[5] <= 1'b1;
            4'b0100: grants_stage3[6] <= 1'b1;
            4'b1000: grants_stage3[7] <= 1'b1;
            default: grants_stage3 <= 8'b0;
          endcase
        end
        req_stage3 <= 1'b1;
      end else if (ack) begin
        req_stage3 <= 1'b0;
        ack_stage3 <= 1'b0;
      end
    end
  end
  
  // Output assignment
  always @(posedge clock) begin
    if (reset) begin
      grants <= 8'b0;
      req_valid <= 1'b0;
    end else begin
      if (req_stage3 && !ack) begin
        grants <= grants_stage3;
        req_valid <= 1'b1;
      end else if (ack) begin
        req_valid <= 1'b0;
      end
    end
  end

endmodule