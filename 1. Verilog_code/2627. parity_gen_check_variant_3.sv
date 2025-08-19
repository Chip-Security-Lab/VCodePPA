//SystemVerilog
module parity_gen_check(
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  tx_data,
  input  logic        rx_parity,
  output logic        tx_parity,
  output logic        error_detected
);

  // Pipeline stage 1: Data preparation
  logic [7:0] tx_data_reg;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_reg <= '0;
    end else begin
      tx_data_reg <= tx_data;
    end
  end

  // Pipeline stage 2: Parity computation
  logic [3:0] parity_low;
  logic [3:0] parity_high;
  logic       data_parity;
  
  assign parity_low  = tx_data_reg[0] ^ tx_data_reg[1] ^ tx_data_reg[2] ^ tx_data_reg[3];
  assign parity_high = tx_data_reg[4] ^ tx_data_reg[5] ^ tx_data_reg[6] ^ tx_data_reg[7];
  assign data_parity = parity_low ^ parity_high;

  // Pipeline stage 3: Output generation
  logic rx_parity_reg;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_parity_reg <= '0;
      tx_parity     <= '0;
      error_detected <= '0;
    end else begin
      rx_parity_reg <= rx_parity;
      tx_parity     <= data_parity;
      error_detected <= rx_parity_reg ^ data_parity;
    end
  end

endmodule