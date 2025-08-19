//SystemVerilog
module mipi_rffe_controller (
  input wire clk, reset_n,
  input wire [7:0] command,
  input wire [7:0] address,
  input wire [7:0] write_data,
  input wire start_transaction, is_write,
  output reg sclk, sdata,
  output reg busy, done
);
  localparam IDLE = 3'd0, START = 3'd1, CMD = 3'd2, ADDR = 3'd3;
  localparam DATA = 3'd4, PARITY = 3'd5, END = 3'd6;

  reg [2:0] state;
  reg [2:0] bit_count; // Use bit_count to count from 0 up to 7
  reg parity;
  reg [7:0] tx_byte; // Register to hold the byte being transmitted for transmission

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sdata <= 1'b1;
      busy <= 1'b0;
      done <= 1'b0;
      bit_count <= 3'd0;
      parity <= 1'b0;
      tx_byte <= 8'd0; // Initialize tx_byte
    end else begin
      reg [2:0] next_state;
      reg [2:0] next_bit_count;
      reg next_sdata;
      reg next_parity;
      reg next_busy;
      reg next_done;
      reg [7:0] next_tx_byte; // Next value for tx_byte

      // Default assignments to maintain current values unless changed by state logic
      next_state = state;
      next_bit_count = bit_count;
      next_sdata = sdata;
      next_parity = parity;
      next_busy = busy;
      next_done = done;
      next_tx_byte = tx_byte; // Default: keep current byte

      case (state)
        IDLE: begin
          if (start_transaction) begin
            next_state = START;
            next_busy = 1'b1;
            next_done = 1'b0;
            next_parity = 1'b0;
            // bit_count will be reset in START state
            // tx_byte will be loaded in START state
          end
        end

        START: begin
          next_sdata = 1'b0; // Start bit
          next_state = CMD;
          next_bit_count = 3'd0; // Start count at 0 for 8 bits (indices 7 down to 0)
          next_tx_byte = command; // Load command for transmission
          next_parity = 1'b0; // Reset parity for the new transaction
        end

        CMD: begin
          next_sdata = tx_byte[7]; // Transmit MSB of the current byte
          next_parity = parity ^ next_sdata;

          next_tx_byte = tx_byte << 1; // Shift left for the next bit

          // Check if count reached 7 (finished 8 bits: 0 to 7)
          if (bit_count == 3'd7) begin
            next_state = ADDR;
            next_bit_count = 3'd0; // Reset count for next state (ADDR)
            next_tx_byte = address; // Load address for transmission
          end else begin
            next_bit_count = bit_count + 1; // Increment count
          end
        end

        ADDR: begin
          next_sdata = tx_byte[7]; // Transmit MSB of the current byte
          next_parity = parity ^ next_sdata;

          next_tx_byte = tx_byte << 1; // Shift left for the next bit

          // Check if count reached 7 (finished 8 bits: 0 to 7)
          if (bit_count == 3'd7) begin
            next_state = is_write ? DATA : PARITY;
            next_bit_count = 3'd0; // Reset count for next state

            if (next_state == DATA) begin
                next_tx_byte = write_data; // Load write_data for transmission
            end else begin
                next_tx_byte = 8'd0; // Not used in PARITY/END/IDLE
            end
          end else begin
            next_bit_count = bit_count + 1; // Increment count
          end
        end

        DATA: begin
          next_sdata = tx_byte[7]; // Transmit MSB of the current byte
          next_parity = parity ^ next_sdata;

          next_tx_byte = tx_byte << 1; // Shift left for the next bit

          // Check if count reached 7 (finished 8 bits: 0 to 7)
          if (bit_count == 3'd7) begin
            next_state = PARITY;
            next_bit_count = 3'd0; // Reset count
            next_tx_byte = 8'd0; // Not used in PARITY/END/IDLE
          end else begin
            next_bit_count = bit_count + 1; // Increment count
          end
        end

        PARITY: begin
          next_sdata = parity; // Transmit the final parity bit
          next_state = END;
          next_bit_count = 3'd0; // Reset count
          next_tx_byte = 8'd0; // Not used
        end

        END: begin
          next_sdata = 1'b1; // Stop bit
          next_busy = 1'b0;
          next_done = 1'b1;
          next_state = IDLE;
          next_bit_count = 3'd0; // Reset count
          next_tx_byte = 8'd0; // Not used
        end

        default: begin
          next_state = IDLE;
          next_bit_count = 3'd0; // Explicitly reset
          next_tx_byte = 8'd0; // Explicitly reset
        end
      endcase

      // Update registers
      state <= next_state;
      bit_count <= next_bit_count;
      sdata <= next_sdata;
      parity <= next_parity;
      busy <= next_busy;
      done <= next_done;
      tx_byte <= next_tx_byte; // Update tx_byte
    end
  end

  // SCLK logic (separate always block as in original)
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sclk <= 1'b1;
    end else if (state != IDLE && state != END) begin
      // Toggle sclk in active states (START, CMD, ADDR, DATA, PARITY)
      sclk <= ~sclk;
    end else begin
      // Ensure sclk is high in IDLE/END states
      sclk <= 1'b1;
    end
  end

endmodule