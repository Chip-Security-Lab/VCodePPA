module time_sliced_arbiter(
  input clk, rst_n,
  input [3:0] req,
  output reg [3:0] gnt,
  output reg busy
);
  reg [1:0] time_slice_counter;
  
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter <= 2'b00;
      gnt <= 4'b0000;
      busy <= 1'b0;
    end else begin
      gnt <= 4'b0000;
      
      if (time_slice_counter == 2'b00 && req[0])
        gnt[0] <= 1'b1;
      else if (time_slice_counter == 2'b01 && req[1])
        gnt[1] <= 1'b1;
      // Continue for other time slices
      
      time_slice_counter <= time_slice_counter + 1'b1;
      busy <= |gnt;
    end
  end
endmodule