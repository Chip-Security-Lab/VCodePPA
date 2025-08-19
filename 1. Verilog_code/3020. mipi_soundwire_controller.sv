module mipi_soundwire_controller (
  input wire clk, reset_n,
  input wire [15:0] audio_in,
  input wire audio_valid,
  output reg sdout, sclk, ws,
  output reg ready
);
  reg [7:0] bit_count;
  reg [15:0] shift_reg;
  reg [9:0] frame_count;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count <= 8'd0;
      frame_count <= 10'd0;
      sclk <= 1'b0;
      ws <= 1'b0;
      ready <= 1'b1;
    end else begin
      sclk <= ~sclk;
      if (sclk) begin // Rising edge
        if (bit_count == 0 && audio_valid && ready) begin
          shift_reg <= audio_in;
          ready <= 1'b0;
        end
        if (bit_count == 8'd15) begin
          ws <= ~ws;
          ready <= 1'b1;
        end
      end else begin // Falling edge
        sdout <= shift_reg[15];
        shift_reg <= {shift_reg[14:0], 1'b0};
        bit_count <= (bit_count == 8'd15) ? 8'd0 : bit_count + 1'b1;
      end
    end
  end
endmodule