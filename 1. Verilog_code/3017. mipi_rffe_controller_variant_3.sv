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

  reg [2:0] state; // 3 bits for 7 states
  reg [2:0] bit_index; // 3 bits for 0 to 7
  reg parity;

  // Calculate the index using 2's complement subtraction: 7 - bit_index
  // This is equivalent to 7 + (-bit_index)
  // -bit_index is equivalent to (~bit_index + 1) in 2's complement
  // We need to perform the operation on sufficient bit width, e.g., 8 bits.
  // Extend bit_index to 8 bits by zero-padding.
  wire [7:0] bit_index_ext = {5'b0, bit_index};
  wire [7:0] seven_const = 8'd7; // Constant 7 as 8 bits
  wire [7:0] neg_bit_index_twos_comp = ~bit_index_ext + 8'd1; // (~bit_index + 1)
  wire [7:0] calculated_index = seven_const + neg_bit_index_twos_comp; // 7 + (~bit_index + 1)

  // Main state machine and data path logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sclk <= 1'b1; // SCLK high in reset
      sdata <= 1'b1; // SDATA high in reset
      busy <= 1'b0;
      done <= 1'b0;
      bit_index <= 3'd0; // Initialize bit_index
      parity <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          busy <= 1'b0;
          done <= 1'b0;
          sclk <= 1'b1; // Ensure sclk is high in IDLE
          sdata <= 1'b1; // Ensure sdata is high in IDLE
          bit_index <= 3'd0; // Reset bit_index
          parity <= 1'b0; // Reset parity
          if (start_transaction) begin
            state <= START;
            busy <= 1'b1;
            done <= 1'b0;
          end
        end

        START: begin
          sdata <= 1'b0; // Start bit (typically low)
          state <= CMD;
          bit_index <= 3'd0; // Start index for CMD (0 corresponds to MSB)
          parity <= 1'b0; // Reset parity for new transaction
        end

        CMD: begin
          // Send MSB first (index 0 corresponds to bit 7)
          sdata <= command[calculated_index];
          parity <= parity ^ command[calculated_index];
          if (bit_index == 3'd7) begin // Check if last bit (index 7, bit 0) sent
            state <= ADDR;
            bit_index <= 3'd0; // Reset index for ADDR
          end else begin
            bit_index <= bit_index + 1'b1;
          end
        end

        ADDR: begin
          // Send MSB first
          sdata <= address[calculated_index];
          parity <= parity ^ address[calculated_index];
          if (bit_index == 3'd7) begin // Check if last bit sent
            state <= is_write ? DATA : PARITY;
            bit_index <= 3'd0; // Reset index for next state
          end else begin
            bit_index <= bit_index + 1'b1;
          end
        end

        DATA: begin
          // Send MSB first
          sdata <= write_data[calculated_index];
          parity <= parity ^ write_data[calculated_index];
          if (bit_index == 3'd7) begin // Check if last bit sent
            state <= PARITY;
            // bit_index doesn't strictly need reset here as PARITY/END are 1 cycle each
            // and it's reset in IDLE.
          end else begin
            bit_index <= bit_index + 1'b1;
          end
        end

        PARITY: begin
          sdata <= parity; // Send parity bit
          state <= END;
          // bit_index value doesn't matter in this state
        end

        END: begin
          sdata <= 1'b1; // Stop bit or bus idle (typically high)
          sclk <= 1'b1; // Ensure sclk is high in END
          busy <= 1'b0; // Transaction finished
          done <= 1'b1; // Indicate completion
          state <= IDLE; // Go back to idle
        end

        default: begin // Should not happen
          state <= IDLE;
          bit_index <= 3'd0;
          parity <= 1'b0;
        end
      endcase
    end
  end

  // SCLK generation logic
  // This block generates the clock signal by toggling it
  // every clock cycle when the state machine is in an active state.
  // This preserves the original code's SCLK timing (clk/2 frequency).
  always @(posedge clk) begin
    if (state != IDLE && state != END) begin
      sclk <= ~sclk;
    end
    // Note: The assignments to sclk in the main always block (reset, IDLE, END)
    // handle the non-toggling states and initial value.
    // Synthesis tools should resolve these multiple assignments.
  end

endmodule