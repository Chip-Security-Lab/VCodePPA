//SystemVerilog
module uart_full_duplex (
  input wire clk, rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [7:0] tx_data,
  input wire tx_start,
  output wire tx_busy,
  output wire [7:0] rx_data,
  output wire rx_ready,
  output wire rx_error
);
  // Internal connections
  wire baud_tick_tx, baud_tick_rx;
  
  // Baud rate generator instance
  uart_baud_generator #(
    .BAUD_TX_MAX(8'd104),  // For 9600 baud @ 1MHz
    .BAUD_RX_MAX(8'd26)    // 4x oversampling
  ) baud_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .baud_tick_tx(baud_tick_tx),
    .baud_tick_rx(baud_tick_rx)
  );
  
  // UART transmitter instance
  uart_transmitter tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .baud_tick(baud_tick_tx),
    .tx_out(tx_out),
    .tx_busy(tx_busy)
  );
  
  // UART receiver instance
  uart_receiver rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_in(rx_in),
    .baud_tick(baud_tick_rx),
    .rx_data(rx_data),
    .rx_ready(rx_ready),
    .rx_error(rx_error)
  );
endmodule

//SystemVerilog
module uart_baud_generator #(
  parameter BAUD_TX_MAX = 8'd104,  // For 9600 baud @ 1MHz
  parameter BAUD_RX_MAX = 8'd26    // 4x oversampling
)(
  input wire clk, rst_n,
  output wire baud_tick_tx, baud_tick_rx
);
  // Baud rate counters
  reg [7:0] baud_count_tx, baud_count_rx;
  
  // Tick outputs
  assign baud_tick_tx = (baud_count_tx == BAUD_TX_MAX);
  assign baud_tick_rx = (baud_count_rx == BAUD_RX_MAX);
  
  // TX counter logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_count_tx <= 8'd0;
    end else begin
      if (baud_tick_tx) begin
        baud_count_tx <= 8'd0;
      end else begin
        baud_count_tx <= baud_count_tx + 1'b1;
      end
    end
  end
  
  // RX counter logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_count_rx <= 8'd0;
    end else begin
      if (baud_tick_rx) begin
        baud_count_rx <= 8'd0;
      end else begin
        baud_count_rx <= baud_count_rx + 1'b1;
      end
    end
  end
endmodule

//SystemVerilog
module uart_transmitter (
  input wire clk, rst_n,
  input wire [7:0] tx_data,
  input wire tx_start,
  input wire baud_tick,
  output wire tx_out,
  output wire tx_busy
);
  // TX state machine states
  localparam TX_IDLE = 2'b00, TX_START = 2'b01, TX_DATA = 2'b10, TX_STOP = 2'b11;
  
  // TX state machine registers
  reg [1:0] tx_state, tx_next_state;
  reg [2:0] tx_bit_pos, tx_next_bit_pos;
  reg [7:0] tx_shift_reg, tx_next_shift_reg;
  reg tx_out_reg, tx_next_out_reg;
  reg tx_busy_reg, tx_next_busy;
  
  // Output assignments
  assign tx_out = tx_out_reg;
  assign tx_busy = tx_busy_reg;
  
  // TX state machine - combinational logic
  always @(*) begin
    // Default: maintain current state
    tx_next_state = tx_state;
    tx_next_bit_pos = tx_bit_pos;
    tx_next_shift_reg = tx_shift_reg;
    tx_next_out_reg = tx_out_reg;
    tx_next_busy = tx_busy_reg;
    
    if (baud_tick) begin
      case (tx_state)
        TX_IDLE: begin
          if (tx_start) begin
            tx_next_state = TX_START;
            tx_next_shift_reg = tx_data;
            tx_next_busy = 1'b1;
          end
        end
        
        TX_START: begin
          tx_next_out_reg = 1'b0;
          tx_next_state = TX_DATA;
          tx_next_bit_pos = 3'b000;
        end
        
        TX_DATA: begin
          tx_next_out_reg = tx_shift_reg[0];
          tx_next_shift_reg = {1'b0, tx_shift_reg[7:1]};
          
          if (tx_bit_pos == 3'b111) begin
            tx_next_state = TX_STOP;
          end else begin
            tx_next_bit_pos = tx_bit_pos + 1'b1;
          end
        end
        
        TX_STOP: begin
          tx_next_out_reg = 1'b1;
          tx_next_state = TX_IDLE;
          tx_next_busy = 1'b0;
        end
      endcase
    end
  end
  
  // TX state machine - sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= TX_IDLE;
      tx_out_reg <= 1'b1;
      tx_busy_reg <= 1'b0;
      tx_bit_pos <= 3'b000;
      tx_shift_reg <= 8'b0;
    end else begin
      tx_state <= tx_next_state;
      tx_out_reg <= tx_next_out_reg;
      tx_busy_reg <= tx_next_busy;
      tx_bit_pos <= tx_next_bit_pos;
      tx_shift_reg <= tx_next_shift_reg;
    end
  end
endmodule

//SystemVerilog
module uart_receiver (
  input wire clk, rst_n,
  input wire rx_in,
  input wire baud_tick,
  output wire [7:0] rx_data,
  output wire rx_ready,
  output wire rx_error
);
  // RX state machine states
  localparam RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;
  
  // RX state machine registers
  reg [1:0] rx_state, rx_next_state;
  reg [2:0] rx_bit_pos, rx_next_bit_pos;
  reg [7:0] rx_shift_reg, rx_next_shift_reg;
  reg rx_ready_reg, rx_next_ready;
  reg rx_error_reg, rx_next_error;
  reg [7:0] rx_data_reg, rx_next_data;
  
  // Output assignments
  assign rx_data = rx_data_reg;
  assign rx_ready = rx_ready_reg;
  assign rx_error = rx_error_reg;
  
  // RX state machine - combinational logic
  always @(*) begin
    // Default: maintain current state
    rx_next_state = rx_state;
    rx_next_bit_pos = rx_bit_pos;
    rx_next_shift_reg = rx_shift_reg;
    rx_next_ready = 1'b0;  // One cycle pulse
    rx_next_error = rx_error_reg;
    rx_next_data = rx_data_reg;
    
    if (baud_tick) begin
      case (rx_state)
        RX_IDLE: begin
          if (rx_in == 1'b0) begin
            rx_next_state = RX_START;
          end
        end
        
        RX_START: begin
          rx_next_state = RX_DATA;
          rx_next_bit_pos = 3'b000;
        end
        
        RX_DATA: begin
          rx_next_shift_reg = {rx_in, rx_shift_reg[7:1]};
          
          if (rx_bit_pos == 3'b111) begin
            rx_next_state = RX_STOP;
          end else begin
            rx_next_bit_pos = rx_bit_pos + 1'b1;
          end
        end
        
        RX_STOP: begin
          rx_next_state = RX_IDLE;
          
          if (rx_in == 1'b1) begin
            rx_next_data = rx_shift_reg;
            rx_next_ready = 1'b1;
            rx_next_error = 1'b0;
          end else begin
            rx_next_error = 1'b1;
          end
        end
      endcase
    end
  end
  
  // RX state machine - sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= RX_IDLE;
      rx_bit_pos <= 3'b000;
      rx_shift_reg <= 8'b0;
      rx_ready_reg <= 1'b0;
      rx_error_reg <= 1'b0;
      rx_data_reg <= 8'b0;
    end else begin
      rx_state <= rx_next_state;
      rx_bit_pos <= rx_next_bit_pos;
      rx_shift_reg <= rx_next_shift_reg;
      rx_ready_reg <= rx_next_ready;
      rx_error_reg <= rx_next_error;
      rx_data_reg <= rx_next_data;
    end
  end
endmodule