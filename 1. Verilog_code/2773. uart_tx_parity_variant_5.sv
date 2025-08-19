//SystemVerilog
module uart_tx_parity #(parameter DWIDTH = 8) (
  input  wire              clk,
  input  wire              rst_n,
  input  wire              tx_en,
  input  wire [DWIDTH-1:0] data_in,
  input  wire [1:0]        parity_mode, // 00:none, 01:odd, 10:even
  output reg               tx_out,
  output reg               tx_active
);

  localparam IDLE = 3'd0, START_BIT = 3'd1, DATA_BITS = 3'd2, PARITY_BIT = 3'd3, STOP_BIT = 3'd4;

  reg [2:0] state, state_d1;
  reg [3:0] bit_index, bit_index_d1;
  reg [DWIDTH-1:0] data_reg, data_reg_d1;
  reg parity, parity_d1;
  reg tx_en_d, tx_en_d1;
  reg [DWIDTH-1:0] data_in_d, data_in_d1;
  reg [1:0] parity_mode_d, parity_mode_d1;

  //////////////////////////////////////////////////////////////////////////////
  // Pipeline Stage 1: Latch inputs (tx_en, data_in, parity_mode)
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_en_d       <= 1'b0;
      data_in_d     <= {DWIDTH{1'b0}};
      parity_mode_d <= 2'b00;
    end else begin
      tx_en_d       <= tx_en;
      data_in_d     <= data_in;
      parity_mode_d <= parity_mode;
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Pipeline Stage 2: Latch pipelined input and calculate parity
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_en_d1       <= 1'b0;
      data_in_d1     <= {DWIDTH{1'b0}};
      parity_mode_d1 <= 2'b00;
      parity_d1      <= 1'b0;
    end else begin
      tx_en_d1       <= tx_en_d;
      data_in_d1     <= data_in_d;
      parity_mode_d1 <= parity_mode_d;
      parity_d1      <= (^data_in_d) ^ parity_mode_d[0];
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // FSM State Register: Handles the current state of the FSM
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (tx_en_d1)
            state <= START_BIT;
        end
        START_BIT: begin
          state <= DATA_BITS;
        end
        DATA_BITS: begin
          if (bit_index < DWIDTH-1)
            state <= DATA_BITS;
          else if (parity_mode_d1 == 2'b00)
            state <= STOP_BIT;
          else
            state <= PARITY_BIT;
        end
        PARITY_BIT: begin
          state <= STOP_BIT;
        end
        STOP_BIT: begin
          state <= IDLE;
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Pipeline State Register: Pipeline delayed state, bit_index, data_reg
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_d1     <= IDLE;
      bit_index_d1 <= 4'd0;
      data_reg_d1  <= {DWIDTH{1'b0}};
    end else begin
      state_d1     <= state;
      bit_index_d1 <= bit_index;
      data_reg_d1  <= data_reg;
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Bit Index Register: Controls the bit index for data transmission
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_index <= 4'd0;
    end else begin
      case (state)
        IDLE: begin
          if (tx_en_d1)
            bit_index <= 4'd0;
        end
        START_BIT: begin
          bit_index <= 4'd0;
        end
        DATA_BITS: begin
          if (bit_index < DWIDTH-1)
            bit_index <= bit_index + 1'b1;
        end
        default: begin
          bit_index <= bit_index;
        end
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Data Register: Holds the data to be transmitted serially
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= {DWIDTH{1'b0}};
    end else begin
      case (state)
        IDLE: begin
          if (tx_en_d1)
            data_reg <= data_in_d1;
        end
        DATA_BITS: begin
          data_reg <= {1'b0, data_reg[DWIDTH-1:1]};
        end
        default: begin
          data_reg <= data_reg;
        end
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Parity Register: Holds the parity bit to be transmitted
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity <= 1'b0;
    end else begin
      if (state == IDLE && tx_en_d1) begin
        parity <= parity_d1;
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Output Logic: Controls tx_out according to FSM state
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_out <= 1'b1;
    end else begin
      case (state)
        IDLE:       tx_out <= 1'b1;
        START_BIT:  tx_out <= 1'b0;
        DATA_BITS:  tx_out <= data_reg[0];
        PARITY_BIT: tx_out <= parity;
        STOP_BIT:   tx_out <= 1'b1;
        default:    tx_out <= 1'b1;
      endcase
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // TX Active Signal: Indicates if transmitter is currently sending data
  //////////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_active <= 1'b0;
    end else begin
      case (state)
        IDLE:      tx_active <= (tx_en_d1) ? 1'b1 : 1'b0;
        START_BIT,
        DATA_BITS,
        PARITY_BIT: tx_active <= 1'b1;
        STOP_BIT:   tx_active <= 1'b0;
        default:    tx_active <= 1'b0;
      endcase
    end
  end

endmodule