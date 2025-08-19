//SystemVerilog
module uart_loopback #(parameter DATA_WIDTH = 8) (
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire                  rx_in,
  output wire                  tx_out,
  input  wire [DATA_WIDTH-1:0] tx_data,
  input  wire                  tx_valid,
  output reg                   tx_ready,
  output reg  [DATA_WIDTH-1:0] rx_data,
  output reg                   rx_valid,
  input  wire                  loopback_enable
);
  // Internal signals
  wire                         tx_to_rx;
  reg  [5:0]                   tx_state, rx_state;
  reg  [2:0]                   tx_bitpos, rx_bitpos;
  reg  [DATA_WIDTH-1:0]        tx_shift, rx_shift;
  reg                          tx_busy;
  reg                          tx_out_reg;

  // One-cold state encoding for TX FSM
  localparam [5:0] TX_IDLE      = 6'b111111;
  localparam [5:0] TX_START_BIT = 6'b111110;
  localparam [5:0] TX_DATA_BITS = 6'b111101;
  localparam [5:0] TX_STOP_BIT  = 6'b111011;
  localparam [5:0] TX_UNUSED4   = 6'b110111;
  localparam [5:0] TX_UNUSED5   = 6'b101111;

  // One-cold state encoding for RX FSM
  localparam [5:0] RX_IDLE      = 6'b111111;
  localparam [5:0] RX_CONFIRM   = 6'b111110;
  localparam [5:0] RX_DATA_BITS = 6'b111101;
  localparam [5:0] RX_STOP_BIT  = 6'b111011;
  localparam [5:0] RX_UNUSED4   = 6'b110111;
  localparam [5:0] RX_UNUSED5   = 6'b101111;

  assign tx_to_rx = loopback_enable ? tx_out : rx_in;
  assign tx_out   = tx_out_reg;

  //==========================================================================
  // TX FSM state management block
  //==========================================================================
  // Handles state transitions and tx_busy control
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state  <= TX_IDLE;
      tx_busy   <= 1'b0;
    end else begin
      case (1'b0)
        tx_state[5]: begin // TX_IDLE
          if (tx_valid && tx_ready) begin
            tx_state <= TX_START_BIT;
            tx_busy  <= 1'b1;
          end
        end
        tx_state[4]: begin // TX_START_BIT
          tx_state <= TX_DATA_BITS;
        end
        tx_state[3]: begin // TX_DATA_BITS
          if (tx_bitpos == DATA_WIDTH-1)
            tx_state <= TX_STOP_BIT;
        end
        tx_state[2]: begin // TX_STOP_BIT
          tx_state <= TX_IDLE;
          tx_busy  <= 1'b0;
        end
        tx_state[1]: begin // TX_UNUSED4 (unused)
          tx_state <= TX_IDLE;
        end
        tx_state[0]: begin // TX_UNUSED5 (unused)
          tx_state <= TX_IDLE;
        end
        default: tx_state <= TX_IDLE;
      endcase
    end
  end

  //==========================================================================
  // TX bit position control block
  //==========================================================================
  // Handles tx_bitpos increment and reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_bitpos <= 3'd0;
    end else begin
      case (1'b0)
        tx_state[4]: begin // TX_START_BIT
          tx_bitpos <= 3'd0;
        end
        tx_state[3]: begin // TX_DATA_BITS
          if (tx_bitpos != DATA_WIDTH-1)
            tx_bitpos <= tx_bitpos + 1'b1;
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // TX shift register control block
  //==========================================================================
  // Handles loading and shifting of tx_shift
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_shift <= {DATA_WIDTH{1'b0}};
    end else begin
      case (1'b0)
        tx_state[5]: begin // TX_IDLE
          if (tx_valid && tx_ready)
            tx_shift <= tx_data;
        end
        tx_state[3]: begin // TX_DATA_BITS
          tx_shift <= {1'b0, tx_shift[DATA_WIDTH-1:1]};
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // TX output and tx_ready signal block
  //==========================================================================
  // Controls tx_out_reg and tx_ready
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_out_reg <= 1'b1;
      tx_ready   <= 1'b1;
    end else begin
      case (1'b0)
        tx_state[5]: begin // TX_IDLE
          tx_out_reg <= 1'b1;
          if (tx_valid && tx_ready)
            tx_ready <= 1'b0;
          else
            tx_ready <= 1'b1;
        end
        tx_state[4]: begin // TX_START_BIT
          tx_out_reg <= 1'b0;
        end
        tx_state[3]: begin // TX_DATA_BITS
          tx_out_reg <= tx_shift[0];
        end
        tx_state[2]: begin // TX_STOP_BIT
          tx_out_reg <= 1'b1;
          tx_ready   <= 1'b1;
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // RX FSM state management block
  //==========================================================================
  // Handles state transitions
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= RX_IDLE;
    end else begin
      case (1'b0)
        rx_state[5]: begin // RX_IDLE
          if (tx_to_rx == 1'b0)
            rx_state <= RX_CONFIRM;
        end
        rx_state[4]: begin // RX_CONFIRM
          rx_state <= RX_DATA_BITS;
        end
        rx_state[3]: begin // RX_DATA_BITS
          if (rx_bitpos == DATA_WIDTH-1)
            rx_state <= RX_STOP_BIT;
        end
        rx_state[2]: begin // RX_STOP_BIT
          rx_state <= RX_IDLE;
        end
        rx_state[1]: begin // RX_UNUSED4 (unused)
          rx_state <= RX_IDLE;
        end
        rx_state[0]: begin // RX_UNUSED5 (unused)
          rx_state <= RX_IDLE;
        end
        default: rx_state <= RX_IDLE;
      endcase
    end
  end

  //==========================================================================
  // RX bit position control block
  //==========================================================================
  // Handles rx_bitpos increment and reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_bitpos <= 3'd0;
    end else begin
      case (1'b0)
        rx_state[4]: begin // RX_CONFIRM
          rx_bitpos <= 3'd0;
        end
        rx_state[3]: begin // RX_DATA_BITS
          if (rx_bitpos != DATA_WIDTH-1)
            rx_bitpos <= rx_bitpos + 1'b1;
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // RX shift register control block
  //==========================================================================
  // Handles shifting in received bits
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_shift <= {DATA_WIDTH{1'b0}};
    end else begin
      case (1'b0)
        rx_state[3]: begin // RX_DATA_BITS
          rx_shift <= {tx_to_rx, rx_shift[DATA_WIDTH-1:1]};
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // RX output data and valid signal block
  //==========================================================================
  // Controls rx_data and rx_valid
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data  <= {DATA_WIDTH{1'b0}};
      rx_valid <= 1'b0;
    end else begin
      case (1'b0)
        rx_state[5]: begin // RX_IDLE
          rx_valid <= 1'b0;
        end
        rx_state[2]: begin // RX_STOP_BIT
          if (tx_to_rx == 1'b1) begin
            rx_data  <= rx_shift;
            rx_valid <= 1'b1;
          end
        end
        default: ;
      endcase
    end
  end

  //==========================================================================
  // Error counter block (loopback test result)
  //==========================================================================
  reg [7:0] error_counter;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter <= 8'b0;
    end else if (loopback_enable && rx_valid) begin
      if (rx_data != tx_data && !error_counter[7]) begin
        error_counter <= error_counter + 1'b1;
      end
    end
  end

endmodule