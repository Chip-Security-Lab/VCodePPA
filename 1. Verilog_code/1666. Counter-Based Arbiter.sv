module counter_arbiter(
  input wire clock, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);
  reg [1:0] count;
  
  always @(posedge clock) begin
    if (reset) begin
      count <= 2'b00;
      grants <= 4'b0000;
    end else begin
      if (requests[count]) grants <= (1 << count);
      else grants <= 4'b0000;
      
      count <= count + 1'b1;
    end
  end
endmodule