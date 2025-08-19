module token_ring_arbiter(
  input wire clk, rst,
  input wire [3:0] req,
  output reg [3:0] grant,
  output reg [1:0] token
);
  always @(posedge clk) begin
    if (rst) begin
      token <= 2'd0;
      grant <= 4'd0;
    end else begin
      grant <= 4'd0;
      case (token)
        2'd0: if (req[0]) grant[0] <= 1'b1;
              else if (req[1]) begin grant[1] <= 1'b1; token <= 2'd1; end
              else if (req[2]) begin grant[2] <= 1'b1; token <= 2'd2; end
              else if (req[3]) begin grant[3] <= 1'b1; token <= 2'd3; end
        2'd1: if (req[1]) grant[1] <= 1'b1;
              else if (req[2]) begin grant[2] <= 1'b1; token <= 2'd2; end
              else if (req[3]) begin grant[3] <= 1'b1; token <= 2'd3; end
              else if (req[0]) begin grant[0] <= 1'b1; token <= 2'd0; end
        2'd2: if (req[2]) grant[2] <= 1'b1;
              else if (req[3]) begin grant[3] <= 1'b1; token <= 2'd3; end
              else if (req[0]) begin grant[0] <= 1'b1; token <= 2'd0; end
              else if (req[1]) begin grant[1] <= 1'b1; token <= 2'd1; end
        2'd3: if (req[3]) grant[3] <= 1'b1;
              else if (req[0]) begin grant[0] <= 1'b1; token <= 2'd0; end
              else if (req[1]) begin grant[1] <= 1'b1; token <= 2'd1; end
              else if (req[2]) begin grant[2] <= 1'b1; token <= 2'd2; end
      endcase
    end
  end
endmodule