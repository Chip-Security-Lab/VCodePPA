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
  reg [3:0] bit_count;
  reg parity;

  // Wires for Parallel Prefix Adder (4-bit decrementer: bit_count - 1)
  // Equivalent to bit_count + 4'b1110 + 1'b1
  wire [3:0] adder_p, adder_g; // Propagate and Generate signals for bit_count + 4'b1110
  wire [4:0] adder_c;         // Carry signals, adder_c[0] is Cin
  wire [3:0] bit_count_minus_1; // Result of the parallel prefix addition

  // Calculate Propagate and Generate for bit_count + 4'b1110
  assign adder_p[0] = bit_count[0] ^ 1'b0;
  assign adder_g[0] = bit_count[0] & 1'b0;
  assign adder_p[1] = bit_count[1] ^ 1'b1;
  assign adder_g[1] = bit_count[1] & 1'b1;
  assign adder_p[2] = bit_count[2] ^ 1'b1;
  assign adder_g[2] = bit_count[2] & 1'b1;
  assign adder_p[3] = bit_count[3] ^ 1'b1;
  assign adder_g[3] = bit_count[3] & 1'b1;

  // Parallel Prefix Carry Calculation (using Kogge-Stone like structure for 4 bits)
  // c[0] = Cin = 1
  // c[i+1] = g[i] | (p[i] & c[i])
  assign adder_c[0] = 1'b1; // Carry-in for bit_count + 4'b1110 + 1
  assign adder_c[1] = adder_g[0] | (adder_p[0] & adder_c[0]);
  assign adder_c[2] = adder_g[1] | (adder_p[1] & adder_c[1]);
  assign adder_c[3] = adder_g[2] | (adder_p[2] & adder_c[2]);
  assign adder_c[4] = adder_g[3] | (adder_p[3] & adder_c[3]); // Final carry out

  // Calculate Sum bits (bit_count - 1)
  // sum[i] = p[i] ^ c[i]
  assign bit_count_minus_1[0] = adder_p[0] ^ adder_c[0];
  assign bit_count_minus_1[1] = adder_p[1] ^ adder_c[1];
  assign bit_count_minus_1[2] = adder_p[2] ^ adder_c[2];
  assign bit_count_minus_1[3] = adder_p[3] ^ adder_c[3];


  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sclk <= 1'b1;
      sdata <= 1'b1;
      busy <= 1'b0;
      done <= 1'b0;
      bit_count <= 4'd0;
      parity <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (start_transaction) begin
            state <= START;
            busy <= 1'b1;
            done <= 1'b0;
            parity <= 1'b0;
          end
        end

        START: begin
          sdata <= 1'b0;
          state <= CMD;
          bit_count <= 4'd7;
        end

        CMD: begin
          sdata <= command[bit_count];
          parity <= parity ^ command[bit_count];
          if (bit_count == 0) begin
            state <= ADDR;
            bit_count <= 4'd7;
          end else begin
            // Decrement bit_count using parallel prefix adder for X - 1 (X + ~1 + 1)
            bit_count <= bit_count_minus_1;
          end
        end

        ADDR: begin
          sdata <= address[bit_count];
          parity <= parity ^ address[bit_count];
          if (bit_count == 0) begin
            state <= is_write ? DATA : PARITY;
            bit_count <= 4'd7;
          end else begin
            // Decrement bit_count using parallel prefix adder for X - 1 (X + ~1 + 1)
            bit_count <= bit_count_minus_1;
          end
        end

        DATA: begin
          sdata <= write_data[bit_count];
          parity <= parity ^ write_data[bit_count];
          if (bit_count == 0) begin
            state <= PARITY;
          end else begin
            // Decrement bit_count using parallel prefix adder for X - 1 (X + ~1 + 1)
            bit_count <= bit_count_minus_1;
          end
        end

        PARITY: begin
          sdata <= parity;
          state <= END;
        end

        END: begin
          sdata <= 1'b1;
          sclk <= 1'b1;
          busy <= 1'b0;
          done <= 1'b1;
          state <= IDLE;
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  // SCLK logic (toggles in each state cycle except IDLE and END)
  always @(posedge clk) begin
    if (state != IDLE && state != END) begin
      sclk <= ~sclk;
    end
  end
endmodule