//SystemVerilog
module time_sliced_arbiter(
  input clk, rst_n,
  input [3:0] req,
  output reg [3:0] gnt,
  output reg busy
);

  reg [1:0] time_slice_counter;
  reg [3:0] next_gnt;
  reg next_busy;
  
  // Pipeline stage 1: Request evaluation with case statement
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter <= 2'b00;
      next_gnt <= 4'b0000;
      next_busy <= 1'b0;
    end else begin
      next_gnt <= 4'b0000;
      
      case (time_slice_counter)
        2'b00: if (req[0]) next_gnt[0] <= 1'b1;
        2'b01: if (req[1]) next_gnt[1] <= 1'b1;
        2'b10: if (req[2]) next_gnt[2] <= 1'b1;
        2'b11: if (req[3]) next_gnt[3] <= 1'b1;
      endcase
      
      time_slice_counter <= time_slice_counter + 1'b1;
      next_busy <= |next_gnt;
    end
  end

  // Pipeline stage 2: Output registration
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      gnt <= 4'b0000;
      busy <= 1'b0;
    end else begin
      gnt <= next_gnt;
      busy <= next_busy;
    end
  end

endmodule