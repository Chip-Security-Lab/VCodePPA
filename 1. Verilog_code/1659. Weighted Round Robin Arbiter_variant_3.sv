//SystemVerilog
module weighted_rr_arbiter(
  input wire clk, rst_b,
  input wire [3:0] req_vec,
  output reg [3:0] gnt_vec
);

  // Pre-calculate weight sums to reduce critical path
  reg [4:0] weight_sums [0:3];
  reg [3:0] weights [0:3];
  reg [3:0] counters [0:3];
  reg [1:0] last_served;
  wire [3:0] valid_reqs;
  wire [3:0] priority_mask;
  
  // Parallel priority calculation
  assign valid_reqs = req_vec & ~gnt_vec;
  assign priority_mask = {4{last_served}} & valid_reqs;
  
  // Arbitration state encoding
  reg [2:0] arb_state;
  localparam IDLE = 3'b000;
  localparam GRANT_0 = 3'b001;
  localparam GRANT_1 = 3'b010;
  localparam GRANT_2 = 3'b011;
  localparam GRANT_3 = 3'b100;
  
  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      weights[0] <= 4'd3; weights[1] <= 4'd2;
      weights[2] <= 4'd4; weights[3] <= 4'd1;
      gnt_vec <= 4'b0; last_served <= 2'b0;
      counters[0] <= 4'd0; counters[1] <= 4'd0;
      counters[2] <= 4'd0; counters[3] <= 4'd0;
      weight_sums[0] <= 5'd0; weight_sums[1] <= 5'd0;
      weight_sums[2] <= 5'd0; weight_sums[3] <= 5'd0;
      arb_state <= IDLE;
    end else begin
      // Pre-calculate weight sums in parallel
      weight_sums[0] <= weights[0] + counters[0];
      weight_sums[1] <= weights[1] + counters[1];
      weight_sums[2] <= weights[2] + counters[2];
      weight_sums[3] <= weights[3] + counters[3];
      
      // Arbitration logic using case statement
      case (arb_state)
        IDLE: begin
          if (valid_reqs[0] && (!priority_mask[0] || weight_sums[0] > weight_sums[1])) begin
            arb_state <= GRANT_0;
            gnt_vec <= 4'b0001;
            last_served <= 2'd0;
            counters[0] <= counters[0] + 1;
          end else if (valid_reqs[1] && (!priority_mask[1] || weight_sums[1] > weight_sums[2])) begin
            arb_state <= GRANT_1;
            gnt_vec <= 4'b0010;
            last_served <= 2'd1;
            counters[1] <= counters[1] + 1;
          end else if (valid_reqs[2] && (!priority_mask[2] || weight_sums[2] > weight_sums[3])) begin
            arb_state <= GRANT_2;
            gnt_vec <= 4'b0100;
            last_served <= 2'd2;
            counters[2] <= counters[2] + 1;
          end else if (valid_reqs[3]) begin
            arb_state <= GRANT_3;
            gnt_vec <= 4'b1000;
            last_served <= 2'd3;
            counters[3] <= counters[3] + 1;
          end else begin
            gnt_vec <= 4'b0000;
          end
        end
        
        GRANT_0: begin
          arb_state <= IDLE;
          gnt_vec <= 4'b0000;
        end
        
        GRANT_1: begin
          arb_state <= IDLE;
          gnt_vec <= 4'b0000;
        end
        
        GRANT_2: begin
          arb_state <= IDLE;
          gnt_vec <= 4'b0000;
        end
        
        GRANT_3: begin
          arb_state <= IDLE;
          gnt_vec <= 4'b0000;
        end
        
        default: begin
          arb_state <= IDLE;
          gnt_vec <= 4'b0000;
        end
      endcase
    end
  end
endmodule