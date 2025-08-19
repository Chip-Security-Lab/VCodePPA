//SystemVerilog
module uart_loopback #(parameter DATA_WIDTH = 8) (
  input wire clk,
  input wire rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output reg tx_ready,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire loopback_enable
);

  // Stage 1: Input registering
  reg rx_in_stage1;
  reg loopback_enable_stage1;
  reg [DATA_WIDTH-1:0] tx_data_stage1;
  reg tx_valid_stage1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_in_stage1 <= 1'b1;
      loopback_enable_stage1 <= 1'b0;
      tx_data_stage1 <= {DATA_WIDTH{1'b0}};
      tx_valid_stage1 <= 1'b0;
    end else begin
      rx_in_stage1 <= rx_in;
      loopback_enable_stage1 <= loopback_enable;
      tx_data_stage1 <= tx_data;
      tx_valid_stage1 <= tx_valid;
    end
  end

  // Stage 2: Loopback mux
  reg tx_to_rx_stage2;
  reg [DATA_WIDTH-1:0] tx_data_stage2;
  reg tx_valid_stage2;
  reg loopback_enable_stage2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_to_rx_stage2 <= 1'b1;
      tx_data_stage2 <= {DATA_WIDTH{1'b0}};
      tx_valid_stage2 <= 1'b0;
      loopback_enable_stage2 <= 1'b0;
    end else begin
      tx_to_rx_stage2 <= loopback_enable_stage1 ? tx_out : rx_in_stage1;
      tx_data_stage2 <= tx_data_stage1;
      tx_valid_stage2 <= tx_valid_stage1;
      loopback_enable_stage2 <= loopback_enable_stage1;
    end
  end

  // TX Pipeline Stages
  reg [1:0] tx_state_stage3, tx_state_stage4;
  reg [2:0] tx_bitpos_stage3, tx_bitpos_stage4;
  reg [DATA_WIDTH-1:0] tx_shift_stage3, tx_shift_stage4;
  reg tx_busy_stage3, tx_busy_stage4;
  reg tx_out_reg_stage3, tx_out_reg_stage4;
  reg tx_ready_stage3, tx_ready_stage4;

  // Stage 3: TX state machine - control and datapath
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state_stage3 <= 2'b00;
      tx_bitpos_stage3 <= 3'b000;
      tx_shift_stage3 <= {DATA_WIDTH{1'b0}};
      tx_out_reg_stage3 <= 1'b1;
      tx_ready_stage3 <= 1'b1;
      tx_busy_stage3 <= 1'b0;
    end else begin
      tx_out_reg_stage3 <= tx_out_reg_stage3;
      tx_ready_stage3 <= tx_ready_stage3;
      tx_busy_stage3 <= tx_busy_stage3;
      tx_bitpos_stage3 <= tx_bitpos_stage3;
      tx_shift_stage3 <= tx_shift_stage3;
      case (tx_state_stage3)
        2'b00: begin // Idle
          if (tx_valid_stage2 && tx_ready_stage3) begin
            tx_shift_stage3 <= tx_data_stage2;
            tx_state_stage3 <= 2'b01;
            tx_ready_stage3 <= 1'b0;
            tx_busy_stage3 <= 1'b1;
          end
        end
        2'b01: begin // Start bit
          tx_out_reg_stage3 <= 1'b0;
          tx_state_stage3 <= 2'b10;
          tx_bitpos_stage3 <= 3'b000;
        end
        2'b10: begin // Data bits
          tx_out_reg_stage3 <= tx_shift_stage3[0];
          tx_shift_stage3 <= {1'b0, tx_shift_stage3[DATA_WIDTH-1:1]};
          if (tx_bitpos_stage3 == DATA_WIDTH-1)
            tx_state_stage3 <= 2'b11;
          else
            tx_bitpos_stage3 <= tx_bitpos_stage3 + 1'b1;
        end
        2'b11: begin // Stop bit
          tx_out_reg_stage3 <= 1'b1;
          tx_state_stage3 <= 2'b00;
          tx_ready_stage3 <= 1'b1;
          tx_busy_stage3 <= 1'b0;
        end
        default: tx_state_stage3 <= 2'b00;
      endcase
    end
  end

  // Stage 4: TX output register pipeline
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_out_reg_stage4 <= 1'b1;
      tx_ready_stage4 <= 1'b1;
      tx_state_stage4 <= 2'b00;
      tx_bitpos_stage4 <= 3'b000;
      tx_shift_stage4 <= {DATA_WIDTH{1'b0}};
      tx_busy_stage4 <= 1'b0;
    end else begin
      tx_out_reg_stage4 <= tx_out_reg_stage3;
      tx_ready_stage4 <= tx_ready_stage3;
      tx_state_stage4 <= tx_state_stage3;
      tx_bitpos_stage4 <= tx_bitpos_stage3;
      tx_shift_stage4 <= tx_shift_stage3;
      tx_busy_stage4 <= tx_busy_stage3;
    end
  end

  assign tx_out = tx_out_reg_stage4;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_ready <= 1'b1;
    end else begin
      tx_ready <= tx_ready_stage4;
    end
  end

  // RX Pipeline Stages
  reg [1:0] rx_state_stage3, rx_state_stage4;
  reg [2:0] rx_bitpos_stage3, rx_bitpos_stage4;
  reg [DATA_WIDTH-1:0] rx_shift_stage3, rx_shift_stage4;
  reg [DATA_WIDTH-1:0] rx_data_stage4;
  reg rx_valid_stage4;

  // Stage 3: RX state machine - control and datapath
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state_stage3 <= 2'b00;
      rx_bitpos_stage3 <= 3'b000;
      rx_shift_stage3 <= {DATA_WIDTH{1'b0}};
    end else begin
      rx_state_stage3 <= rx_state_stage3;
      rx_bitpos_stage3 <= rx_bitpos_stage3;
      rx_shift_stage3 <= rx_shift_stage3;
      case (rx_state_stage3)
        2'b00: begin // Idle
          if (tx_to_rx_stage2 == 1'b0)
            rx_state_stage3 <= 2'b01; // Start bit
        end
        2'b01: begin // Confirm start
          rx_state_stage3 <= 2'b10;
          rx_bitpos_stage3 <= 3'b000;
        end
        2'b10: begin // Data bits
          rx_shift_stage3 <= {tx_to_rx_stage2, rx_shift_stage3[DATA_WIDTH-1:1]};
          if (rx_bitpos_stage3 == DATA_WIDTH-1)
            rx_state_stage3 <= 2'b11;
          else
            rx_bitpos_stage3 <= rx_bitpos_stage3 + 1'b1;
        end
        2'b11: begin // Stop bit
          rx_state_stage3 <= 2'b00;
        end
        default: rx_state_stage3 <= 2'b00;
      endcase
    end
  end

  // Stage 4: RX output register pipeline
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state_stage4 <= 2'b00;
      rx_bitpos_stage4 <= 3'b000;
      rx_shift_stage4 <= {DATA_WIDTH{1'b0}};
      rx_data_stage4 <= {DATA_WIDTH{1'b0}};
      rx_valid_stage4 <= 1'b0;
    end else begin
      rx_state_stage4 <= rx_state_stage3;
      rx_bitpos_stage4 <= rx_bitpos_stage3;
      rx_shift_stage4 <= rx_shift_stage3;
      rx_valid_stage4 <= 1'b0;
      if (rx_state_stage3 == 2'b11 && tx_to_rx_stage2 == 1'b1) begin
        rx_data_stage4 <= rx_shift_stage3;
        rx_valid_stage4 <= 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data <= {DATA_WIDTH{1'b0}};
      rx_valid <= 1'b0;
    end else begin
      rx_data <= rx_data_stage4;
      rx_valid <= rx_valid_stage4;
    end
  end

  // Error counter pipeline
  reg [7:0] error_counter_stage1, error_counter_stage2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter_stage1 <= 8'b0;
    end else if (loopback_enable_stage2 && rx_valid_stage4) begin
      if (rx_data_stage4 != tx_data_stage2 && !error_counter_stage1[7]) begin
        error_counter_stage1 <= error_counter_stage1 + 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_counter_stage2 <= 8'b0;
    end else begin
      error_counter_stage2 <= error_counter_stage1;
    end
  end

endmodule