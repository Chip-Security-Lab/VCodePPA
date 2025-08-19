//SystemVerilog
module reset_sequencer (
  input wire clk,
  input wire global_rst,
  input wire ready,          // Ready signal from receiver
  output reg valid,          // Valid signal to receiver
  output reg [3:0] rst_data  // Combined reset signals with additional information
);
  
  reg [3:0] seq_counter;
  reg [2:0] rst_domains;     // Internal register for reset domains
  
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      seq_counter <= 4'd0;
      rst_domains <= 3'b111;
      valid <= 1'b0;
      rst_data <= 4'b1111;
    end else begin
      // Counter logic with handshake control
      if (valid && ready) begin
        // Increment counter when handshake completes
        seq_counter <= (seq_counter == 4'd15) ? seq_counter : seq_counter + 4'd1;
        valid <= 1'b0;  // Deassert valid after successful handshake
      end else if (!valid) begin
        // Optimized comparison logic using range checks instead of individual comparisons
        case (seq_counter)
          4'd0, 4'd1, 4'd2: rst_domains <= 3'b111;  // All domains in reset
          4'd3, 4'd4, 4'd5, 4'd6: rst_domains <= 3'b110;  // Domain 1 out of reset
          4'd7, 4'd8, 4'd9, 4'd10: rst_domains <= 3'b100;  // Domains 1,2 out of reset
          default: rst_domains <= 3'b000;  // All domains out of reset
        endcase
        
        // Combine reset domains into data output with extra status bit
        rst_data <= {1'b0, rst_domains};
        valid <= 1'b1;  // Assert valid to indicate new data is ready
      end
    end
  end
endmodule