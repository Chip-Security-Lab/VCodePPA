//SystemVerilog
module uart_loopback #(parameter DATA_WIDTH = 8) (
  input wire clk, rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output reg tx_ready,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire loopback_enable
);
  // Internal signals
  wire tx_to_rx;
  reg [1:0] tx_state, rx_state;
  reg [2:0] tx_bitpos, rx_bitpos;
  reg [DATA_WIDTH-1:0] tx_shift, rx_shift;
  reg tx_busy;
  reg tx_out_reg;
  reg rx_in_reg;
  reg tx_out_muxed_reg;

  // Input register for rx_in
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_in_reg <= 1'b1;
    end else begin
      rx_in_reg <= rx_in;
    end
  end

  // Output register for loopback mux result
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_out_muxed_reg <= 1'b1;
    end else begin
      if (loopback_enable) begin
        tx_out_muxed_reg <= tx_out;
      end else begin
        tx_out_muxed_reg <= rx_in_reg;
      end
    end
  end

  assign tx_to_rx = tx_out_muxed_reg;
  assign tx_out = tx_out_reg;

  // TX state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= 2'b00;
      tx_bitpos <= 3'b000;
      tx_shift <= {DATA_WIDTH{1'b0}};
      tx_out_reg <= 1'b1; // Idle high
      tx_ready <= 1'b1;
      tx_busy <= 1'b0;
    end else begin
      case (tx_state)
        2'b00: begin // Idle
          if (tx_valid && tx_ready) begin
            tx_shift <= tx_data;
            tx_state <= 2'b01;
            tx_ready <= 1'b0;
            tx_busy <= 1'b1;
          end
        end
        2'b01: begin // Start bit
          tx_out_reg <= 1'b0;
          tx_state <= 2'b10;
          tx_bitpos <= 3'b000;
        end
        2'b10: begin // Data bits
          tx_out_reg <= tx_shift[0];
          tx_shift <= {1'b0, tx_shift[DATA_WIDTH-1:1]};
          if (tx_bitpos == DATA_WIDTH-1) begin
            tx_state <= 2'b11;
          end else begin
            tx_bitpos <= tx_bitpos + 1'b1;
          end
        end
        2'b11: begin // Stop bit
          tx_out_reg <= 1'b1;
          tx_state <= 2'b00;
          tx_ready <= 1'b1;
          tx_busy <= 1'b0;
        end
        default: tx_state <= 2'b00;
      endcase
    end
  end

  // RX state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= 2'b00;
      rx_bitpos <= 3'b000;
      rx_shift <= {DATA_WIDTH{1'b0}};
      rx_data <= {DATA_WIDTH{1'b0}};
      rx_valid <= 1'b0;
    end else begin
      case (rx_state)
        2'b00: begin // Idle
          rx_valid <= 1'b0;
          if (tx_to_rx == 1'b0) begin
            rx_state <= 2'b01;
          end
        end
        2'b01: begin // Confirm start
          rx_state <= 2'b10;
          rx_bitpos <= 3'b000;
        end
        2'b10: begin // Data bits
          rx_shift <= {tx_to_rx, rx_shift[DATA_WIDTH-1:1]};
          if (rx_bitpos == DATA_WIDTH-1) begin
            rx_state <= 2'b11;
          end else begin
            rx_bitpos <= rx_bitpos + 1'b1;
          end
        end
        2'b11: begin // Stop bit
          if (tx_to_rx == 1'b1) begin
            rx_data <= rx_shift;
            rx_valid <= 1'b1;
          end
          rx_state <= 2'b00;
        end
        default: rx_state <= 2'b00;
      endcase
    end
  end

  // Borrow-based subtractor for error comparison
  wire [DATA_WIDTH-1:0] subtractor_result;
  wire subtractor_borrow;

  borrow_subtractor_8bit u_borrow_subtractor_8bit (
    .minuend(rx_data),
    .subtrahend(tx_data),
    .difference(subtractor_result),
    .borrow_out(subtractor_borrow)
  );

  // Test result comparison when in loopback mode
  reg [7:0] error_counter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter <= 8'b0;
    end else begin
      if (loopback_enable && rx_valid) begin
        if ((subtractor_result != 8'b0) && (error_counter[7] == 1'b0)) begin
          error_counter <= error_counter + 8'b1;
        end
      end
    end
  end
endmodule

// 8-bit Borrow Subtractor Module
module borrow_subtractor_8bit (
  input  wire [7:0] minuend,
  input  wire [7:0] subtrahend,
  output wire [7:0] difference,
  output wire borrow_out
);
  wire [7:0] borrow;

  // Bit 0
  assign difference[0] = minuend[0] ^ subtrahend[0];
  assign borrow[0] = (~minuend[0] & subtrahend[0]);

  // Bit 1
  assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
  assign borrow[1] = ((~minuend[1]) & (subtrahend[1] | borrow[0])) | (subtrahend[1] & borrow[0]);

  // Bit 2
  assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
  assign borrow[2] = ((~minuend[2]) & (subtrahend[2] | borrow[1])) | (subtrahend[2] & borrow[1]);

  // Bit 3
  assign difference[3] = minuend[3] ^ subtrahend[3] ^ borrow[2];
  assign borrow[3] = ((~minuend[3]) & (subtrahend[3] | borrow[2])) | (subtrahend[3] & borrow[2]);

  // Bit 4
  assign difference[4] = minuend[4] ^ subtrahend[4] ^ borrow[3];
  assign borrow[4] = ((~minuend[4]) & (subtrahend[4] | borrow[3])) | (subtrahend[4] & borrow[3]);

  // Bit 5
  assign difference[5] = minuend[5] ^ subtrahend[5] ^ borrow[4];
  assign borrow[5] = ((~minuend[5]) & (subtrahend[5] | borrow[4])) | (subtrahend[5] & borrow[4]);

  // Bit 6
  assign difference[6] = minuend[6] ^ subtrahend[6] ^ borrow[5];
  assign borrow[6] = ((~minuend[6]) & (subtrahend[6] | borrow[5])) | (subtrahend[6] & borrow[5]);

  // Bit 7
  assign difference[7] = minuend[7] ^ subtrahend[7] ^ borrow[6];
  assign borrow[7] = ((~minuend[7]) & (subtrahend[7] | borrow[6])) | (subtrahend[7] & borrow[6]);

  assign borrow_out = borrow[7];
endmodule