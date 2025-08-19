module reset_sequencer (
  input wire clk,
  input wire global_rst,
  output reg rst_domain1,
  output reg rst_domain2,
  output reg rst_domain3
);
  reg [3:0] seq_counter;
  
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      seq_counter <= 4'd0;
      {rst_domain1, rst_domain2, rst_domain3} <= 3'b111;
    end else begin
      seq_counter <= seq_counter + (seq_counter < 4'd15);
      rst_domain1 <= (seq_counter < 4'd3);
      rst_domain2 <= (seq_counter < 4'd7);
      rst_domain3 <= (seq_counter < 4'd11);
    end
  end
endmodule