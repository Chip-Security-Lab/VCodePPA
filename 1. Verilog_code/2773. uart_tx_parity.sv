module uart_tx_parity #(parameter DWIDTH = 8) (
  input wire clk, rst_n, tx_en,
  input wire [DWIDTH-1:0] data_in,
  input wire [1:0] parity_mode, // 00:none, 01:odd, 10:even
  output reg tx_out, tx_active
);
  localparam IDLE = 0, START_BIT = 1, DATA_BITS = 2, PARITY_BIT = 3, STOP_BIT = 4;
  reg [2:0] state;
  reg [3:0] bit_index;
  reg [DWIDTH-1:0] data_reg;
  reg parity;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      tx_out <= 1'b1;
      tx_active <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          tx_out <= 1'b1;
          if (tx_en) begin
            data_reg <= data_in;
            state <= START_BIT;
            tx_active <= 1'b1;
            parity <= ^data_in ^ parity_mode[0]; // Calculate parity
          end
        end
        START_BIT: begin tx_out <= 1'b0; state <= DATA_BITS; bit_index <= 0; end
        DATA_BITS: begin
          tx_out <= data_reg[0];
          data_reg <= {1'b0, data_reg[DWIDTH-1:1]};
          if (bit_index < DWIDTH-1) bit_index <= bit_index + 1'b1;
          else state <= (parity_mode == 2'b00) ? STOP_BIT : PARITY_BIT;
        end
        PARITY_BIT: begin tx_out <= parity; state <= STOP_BIT; end
        STOP_BIT: begin tx_out <= 1'b1; state <= IDLE; tx_active <= 1'b0; end
      endcase
    end
  end
endmodule