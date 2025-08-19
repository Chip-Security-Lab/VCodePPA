//SystemVerilog
module sync_left_shifter #(parameter W=32) (
  input wire Clock,
  input wire Enable,
  input wire [W-1:0] DataIn,
  input wire [4:0] ShiftAmount,
  output reg [W-1:0] DataOut
);

  reg [W-1:0] pipeline_data_in;
  reg [4:0]   pipeline_shift_amount;
  reg [W-1:0] shifted_data_pipeline;

  // Pipeline stage 1: Register inputs to break long combinational path
  always @(posedge Clock) begin
    if (Enable) begin
      pipeline_data_in      <= DataIn;
      pipeline_shift_amount <= ShiftAmount;
    end
  end

  // Pipeline stage 2: Perform shift operation on registered inputs
  always @(posedge Clock) begin
    if (Enable) begin
      shifted_data_pipeline <= pipeline_data_in << pipeline_shift_amount;
    end
  end

  // Pipeline stage 3: Register output
  always @(posedge Clock) begin
    if (Enable) begin
      DataOut <= shifted_data_pipeline;
    end
    // No else to maintain value when disabled
  end

endmodule