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
  reg [5:0] tx_state, tx_state_next;
  reg [5:0] rx_state, rx_state_next;
  reg [2:0] tx_bitpos, tx_bitpos_next;
  reg [2:0] rx_bitpos, rx_bitpos_next;
  reg [DATA_WIDTH-1:0] tx_shift, tx_shift_next;
  reg [DATA_WIDTH-1:0] rx_shift, rx_shift_next;
  reg tx_busy, tx_busy_next;
  reg tx_out_reg, tx_out_reg_next;
  reg tx_ready_next;
  reg [DATA_WIDTH-1:0] rx_data_next;
  reg rx_valid_next;

  // State encoding - One Hot
  localparam [5:0] 
    TX_IDLE      = 6'b000001,
    TX_START     = 6'b000010,
    TX_DATA      = 6'b000100,
    TX_STOP      = 6'b001000,
    TX_UNUSED1   = 6'b010000,
    TX_UNUSED2   = 6'b100000;

  localparam [5:0]
    RX_IDLE      = 6'b000001,
    RX_CONFIRM   = 6'b000010,
    RX_DATA      = 6'b000100,
    RX_STOP      = 6'b001000,
    RX_UNUSED1   = 6'b010000,
    RX_UNUSED2   = 6'b100000;

  // Loopback mux with if-else structure
  assign tx_to_rx = (loopback_enable == 1'b1) ? tx_out : rx_in;
  assign tx_out = tx_out_reg;

  // TX state machine combinational
  always @* begin
    tx_state_next = tx_state;
    tx_bitpos_next = tx_bitpos;
    tx_shift_next = tx_shift;
    tx_out_reg_next = tx_out_reg;
    tx_ready_next = tx_ready;
    tx_busy_next = tx_busy;

    case (tx_state)
      TX_IDLE: begin
        tx_out_reg_next = 1;
        tx_ready_next = 1;
        tx_busy_next = 0;
        if (tx_valid && tx_ready) begin
          tx_shift_next = tx_data;
          tx_state_next = TX_START;
          tx_ready_next = 0;
          tx_busy_next = 1;
        end
      end
      TX_START: begin
        tx_out_reg_next = 0;
        tx_state_next = TX_DATA;
        tx_bitpos_next = 0;
      end
      TX_DATA: begin
        tx_out_reg_next = tx_shift[0];
        tx_shift_next = {1'b0, tx_shift[DATA_WIDTH-1:1]};
        if (tx_bitpos == DATA_WIDTH-1) begin
          tx_state_next = TX_STOP;
        end else begin
          tx_bitpos_next = tx_bitpos + 1;
        end
      end
      TX_STOP: begin
        tx_out_reg_next = 1;
        tx_state_next = TX_IDLE;
        tx_ready_next = 1;
        tx_busy_next = 0;
      end
      default: begin
        tx_state_next = TX_IDLE;
      end
    endcase
  end

  // TX state machine sequential
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= TX_IDLE;
      tx_bitpos <= 0;
      tx_shift <= 0;
      tx_out_reg <= 1;
      tx_ready <= 1;
      tx_busy <= 0;
    end else begin
      tx_state <= tx_state_next;
      tx_bitpos <= tx_bitpos_next;
      tx_shift <= tx_shift_next;
      tx_out_reg <= tx_out_reg_next;
      tx_ready <= tx_ready_next;
      tx_busy <= tx_busy_next;
    end
  end

  // RX state machine combinational
  always @* begin
    rx_state_next = rx_state;
    rx_bitpos_next = rx_bitpos;
    rx_shift_next = rx_shift;
    rx_data_next = rx_data;
    rx_valid_next = rx_valid;

    case (rx_state)
      RX_IDLE: begin
        rx_valid_next = 0;
        if (tx_to_rx == 0) begin
          rx_state_next = RX_CONFIRM;
        end
      end
      RX_CONFIRM: begin
        rx_state_next = RX_DATA;
        rx_bitpos_next = 0;
      end
      RX_DATA: begin
        rx_shift_next = {tx_to_rx, rx_shift[DATA_WIDTH-1:1]};
        if (rx_bitpos == DATA_WIDTH-1) begin
          rx_state_next = RX_STOP;
        end else begin
          rx_bitpos_next = rx_bitpos + 1;
        end
      end
      RX_STOP: begin
        if (tx_to_rx == 1) begin
          rx_data_next = rx_shift;
          rx_valid_next = 1;
        end
        rx_state_next = RX_IDLE;
      end
      default: begin
        rx_state_next = RX_IDLE;
      end
    endcase
  end

  // RX state machine sequential
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= RX_IDLE;
      rx_bitpos <= 0;
      rx_shift <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else begin
      rx_state <= rx_state_next;
      rx_bitpos <= rx_bitpos_next;
      rx_shift <= rx_shift_next;
      rx_data <= rx_data_next;
      rx_valid <= rx_valid_next;
    end
  end

  // Test result comparison when in loopback mode
  reg [7:0] error_counter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter <= 0;
    end else begin
      if (loopback_enable == 1'b1) begin
        if (rx_valid == 1'b1) begin
          if ((rx_data != tx_data) && (error_counter[7] == 1'b0)) begin
            error_counter <= error_counter + 1;
          end
        end
      end
    end
  end
endmodule