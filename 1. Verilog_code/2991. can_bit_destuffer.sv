module can_bit_destuffer(
  input wire clk, rst_n,
  input wire data_in, data_valid,
  input wire destuffing_active,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);
  reg [2:0] same_bit_count;
  reg last_bit;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 0;
      last_bit <= 0;
      data_out <= 1;
      data_out_valid <= 0;
      stuff_error <= 0;
    end else begin
      data_out_valid <= 0;
      
      if (data_valid && destuffing_active) begin
        if (same_bit_count == 4 && data_in == last_bit) begin
          stuff_error <= 1;  // Six consecutive identical bits is an error
        end else if (same_bit_count == 4) begin
          // This is a stuff bit, don't forward it
          same_bit_count <= 0;
          last_bit <= data_in;
        end else begin
          data_out <= data_in;
          data_out_valid <= 1;
          same_bit_count <= (data_in == last_bit) ? same_bit_count + 1 : 0;
          last_bit <= data_in;
        end
      end
    end
  end
endmodule