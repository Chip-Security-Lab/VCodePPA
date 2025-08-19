//SystemVerilog
module time_sliced_arbiter(
  input clk, rst_n,
  input [3:0] req,
  output reg [3:0] gnt,
  output reg busy
);
  reg [1:0] time_slice_counter;
  wire [3:0] slice_match;
  
  // Generate slice match signals using a single comparison operation
  assign slice_match[0] = (time_slice_counter == 2'b00);
  assign slice_match[1] = (time_slice_counter == 2'b01);
  assign slice_match[2] = (time_slice_counter == 2'b10);
  assign slice_match[3] = (time_slice_counter == 2'b11);
  
  // Counter control logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter <= 2'b00;
    end else begin
      time_slice_counter <= time_slice_counter + 1'b1;
    end
  end
  
  // Grant generation logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gnt <= 4'b0000;
    end else begin
      gnt <= req & {4{1'b1}} & {
        slice_match[3],
        slice_match[2],
        slice_match[1],
        slice_match[0]
      };
    end
  end
  
  // Busy signal generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy <= 1'b0;
    end else begin
      busy <= |gnt;
    end
  end
endmodule