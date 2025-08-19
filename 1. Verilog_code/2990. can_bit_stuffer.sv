module can_bit_stuffer(
  input wire clk, rst_n,
  input wire data_in, data_valid,
  input wire stuffing_active,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);
  reg [2:0] same_bit_count;
  reg last_bit;
  reg stuffed_bit;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 0;
      last_bit <= 0;
      stuffed_bit <= 0;
      data_out <= 1;
      data_out_valid <= 0;
      stuff_error <= 0;
    end else begin
      data_out_valid <= 0;
      
      if (data_valid && stuffing_active) begin
        if (same_bit_count == 4 && data_in == last_bit) begin
          // Insert stuff bit (complement of last_bit)
          data_out <= ~last_bit;
          data_out_valid <= 1;
          same_bit_count <= 0;
          stuffed_bit <= 1;
        end else begin
          data_out <= data_in;
          data_out_valid <= 1;
          same_bit_count <= (data_in == last_bit) ? same_bit_count + 1 : 0;
          last_bit <= data_in;
          stuffed_bit <= 0;
        end
      end
    end
  end
endmodule