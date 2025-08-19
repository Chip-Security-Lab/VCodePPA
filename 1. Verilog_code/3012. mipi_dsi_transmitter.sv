module mipi_dsi_transmitter #(
  parameter DATA_LANES = 2,
  parameter BYTE_WIDTH = 8
)(
  input wire clk_hs, rst_n,
  input wire [BYTE_WIDTH-1:0] pixel_data,
  input wire start_tx, is_command,
  output reg [DATA_LANES-1:0] hs_data_out,
  output reg hs_clk_out,
  output reg tx_done, busy
);
  localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
  reg [1:0] state;
  reg [5:0] counter;
  
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      state <= IDLE;
      hs_data_out <= {DATA_LANES{1'b0}};
      tx_done <= 1'b0;
      busy <= 1'b0;
    end else case (state)
      IDLE: if (start_tx) begin state <= SYNC; busy <= 1'b1; end
      SYNC: begin state <= DATA; counter <= 6'b0; end
      DATA: if (counter == 6'd32) state <= EOP; else counter <= counter + 1'b1;
      EOP:  begin tx_done <= 1'b1; state <= IDLE; busy <= 1'b0; end
    endcase
  end
endmodule