//SystemVerilog
module weighted_rr_arbiter(
  input wire clk, rst_b,
  input wire [3:0] req_vec,
  output reg [3:0] gnt_vec
);
  reg [3:0] weights [0:3];
  reg [3:0] counters [0:3];
  reg [1:0] last_served;
  
  always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
      weights[0] <= 4'd3; weights[1] <= 4'd2;
      weights[2] <= 4'd4; weights[3] <= 4'd1;
      gnt_vec <= 4'b0; last_served <= 2'b0;
      counters[0] <= 4'd0; counters[1] <= 4'd0;
      counters[2] <= 4'd0; counters[3] <= 4'd0;
    end else begin
      // Weighted round-robin arbitration logic
      if (req_vec[0] && counters[0] >= weights[0]) begin
        gnt_vec <= 4'b0001;
        last_served <= 2'd0;
      end else if (req_vec[1] && counters[1] >= weights[1]) begin
        gnt_vec <= 4'b0010;
        last_served <= 2'd1;
      end else if (req_vec[2] && counters[2] >= weights[2]) begin
        gnt_vec <= 4'b0100;
        last_served <= 2'd2;
      end else if (req_vec[3] && counters[3] >= weights[3]) begin
        gnt_vec <= 4'b1000;
        last_served <= 2'd3;
      end else begin
        gnt_vec <= 4'b0000;
        last_served <= last_served;
      end
      
      // Counter update logic
      if (gnt_vec[0]) begin
        counters[0] <= 4'd0;
      end else if (req_vec[0]) begin
        counters[0] <= counters[0] + 1'b1;
      end else begin
        counters[0] <= counters[0];
      end
      
      if (gnt_vec[1]) begin
        counters[1] <= 4'd0;
      end else if (req_vec[1]) begin
        counters[1] <= counters[1] + 1'b1;
      end else begin
        counters[1] <= counters[1];
      end
      
      if (gnt_vec[2]) begin
        counters[2] <= 4'd0;
      end else if (req_vec[2]) begin
        counters[2] <= counters[2] + 1'b1;
      end else begin
        counters[2] <= counters[2];
      end
      
      if (gnt_vec[3]) begin
        counters[3] <= 4'd0;
      end else if (req_vec[3]) begin
        counters[3] <= counters[3] + 1'b1;
      end else begin
        counters[3] <= counters[3];
      end
    end
  end
endmodule