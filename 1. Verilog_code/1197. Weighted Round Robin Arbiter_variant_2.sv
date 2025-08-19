//SystemVerilog
module weighted_rr_arbiter(
  input clk, rst,
  input [2:0] req,
  input [1:0] weights [2:0],  // Weight for each requester
  output reg [2:0] grant
);
  reg [2:0] count [2:0];
  reg [1:0] current;
  
  always @(posedge clk) begin
    if (rst) begin
      current <= 0;
      grant <= 0;
      count[0] <= 0; count[1] <= 0; count[2] <= 0;
    end else begin
      case ({req[current], (count[current] < weights[current])})
        2'b11: begin  // Current requester is active and count is less than weight
          grant <= 0;
          grant[current] <= 1'b1;
          count[current] <= count[current] + 1;
        end
        
        default: begin  // Either no request from current or count reached weight
          grant <= 0;
          count[current] <= 0;
          current <= (current + 1) % 3;
        end
      endcase
    end
  end
endmodule