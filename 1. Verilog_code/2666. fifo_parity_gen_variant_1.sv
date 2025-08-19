//SystemVerilog
module fifo_parity_gen(
  input clk, rst_n,
  // Valid-Ready interface for input
  input [7:0] data_in,
  input valid_in,
  output reg ready_in,
  // Valid-Ready interface for output
  output reg fifo_parity,
  output reg valid_out,
  input ready_out,
  // Status outputs
  output reg [3:0] fifo_count
);

  // Data path registers
  reg [7:0] data_pipe;
  reg data_parity;
  reg parity_acc;
  reg transfer_in;
  reg transfer_out;
  
  // Define transfer conditions
  assign transfer_in = valid_in && ready_in;
  assign transfer_out = valid_out && ready_out;

  // Ready logic - ready when not at max capacity
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ready_in <= 1'b1;
    end else begin
      ready_in <= (fifo_count < 4'b1111);
    end
  end

  // Input stage with valid-ready handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_pipe <= 8'b0;
      data_parity <= 1'b0;
    end else if (transfer_in) begin
      data_pipe <= data_in;
      data_parity <= ^data_in;
    end
  end

  // FIFO count management
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_count <= 4'b0000;
      parity_acc <= 1'b0;
    end else begin
      case ({transfer_in, transfer_out})
        2'b10: begin // Only write
          fifo_count <= fifo_count + 1'b1;
          parity_acc <= parity_acc ^ data_parity;
        end
        2'b01: begin // Only read
          if (fifo_count > 0) 
            fifo_count <= fifo_count - 1'b1;
        end
        2'b11: begin // Simultaneous read and write
          parity_acc <= parity_acc ^ data_parity;
          // Count remains the same
        end
        default: begin // No transfer
          // Maintain current state
        end
      endcase
    end
  end

  // Output stage with valid-ready handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_parity <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      if (transfer_out) begin
        valid_out <= 1'b0; // Reset valid after successful transfer
      end else if (fifo_count > 0 && !valid_out) begin
        fifo_parity <= parity_acc;
        valid_out <= 1'b1; // Set valid when data is available and not already asserted
      end
    end
  end

endmodule