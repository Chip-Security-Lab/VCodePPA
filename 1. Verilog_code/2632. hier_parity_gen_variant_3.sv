//SystemVerilog
// Top-level module for hierarchical parity generation with Req-Ack handshaking
module hier_parity_gen(
  input clk,
  input rst_n,
  input [31:0] wide_data,
  input req,           // Request signal (previously 'valid')
  output reg ack,      // Acknowledge signal (previously 'ready')
  output reg parity,
  output reg data_valid // Indicates parity result is valid
);

  // Control signals
  reg processing;
  reg [1:0] state;
  localparam IDLE = 2'b00, COMPUTE = 2'b01, COMPLETE = 2'b10;

  // Instantiate submodules
  wire p1, p2;
  reg [31:0] data_reg;

  // Calculate parity for the first half of the data
  parity_calculator u1 (
    .data(data_reg[15:0]),
    .parity(p1)
  );

  // Calculate parity for the second half of the data
  parity_calculator u2 (
    .data(data_reg[31:16]),
    .parity(p2)
  );

  // FSM for Req-Ack handshaking
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      ack <= 1'b0;
      data_reg <= 32'b0;
      parity <= 1'b0;
      data_valid <= 1'b0;
      processing <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          data_valid <= 1'b0;
          if (req && !processing) begin
            ack <= 1'b1;
            data_reg <= wide_data;
            processing <= 1'b1;
            state <= COMPUTE;
          end else begin
            ack <= 1'b0;
          end
        end

        COMPUTE: begin
          ack <= 1'b0;
          parity <= p1 ^ p2;
          state <= COMPLETE;
        end

        COMPLETE: begin
          data_valid <= 1'b1;
          if (!req) begin
            processing <= 1'b0;
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

// Submodule for parity calculation
module parity_calculator(
  input [15:0] data,
  output parity
);
  assign parity = ^data; // Calculate parity using XOR reduction
endmodule