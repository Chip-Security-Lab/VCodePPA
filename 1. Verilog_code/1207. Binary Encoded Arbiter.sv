module binary_encoded_arbiter #(parameter WIDTH=4) (
  input clk, reset_n,
  input [WIDTH-1:0] req_i,
  output reg [$clog2(WIDTH)-1:0] sel_o,
  output reg valid_o
);
  integer i;
  reg found;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sel_o <= 0;
      valid_o <= 0;
    end else begin
      found = 0;
      valid_o <= |req_i;
      
      for (i = 0; i < WIDTH; i = i + 1) begin
        if (req_i[i] && !found) begin
          sel_o <= i[$clog2(WIDTH)-1:0];
          found = 1;
        end
      end
    end
  end
endmodule