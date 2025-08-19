//SystemVerilog
module priority_reset(
  input clk, global_rst, subsystem_rst, local_rst,
  input [7:0] data_in,
  input ready,
  output reg valid,
  output reg [7:0] data_out
);
  
  reg [7:0] data_reg;
  reg transfer_complete;
  
  // Pre-compute reset conditions to move registers backward
  reg reset_condition;
  reg [1:0] reset_type;
  reg [7:0] next_data_out;
  
  // Determine reset condition and type in combinational logic
  always @(*) begin
    if (global_rst) begin
      reset_condition = 1'b1;
      reset_type = 2'b00; // global reset
      next_data_out = 8'h00;
    end else if (subsystem_rst) begin
      reset_condition = 1'b1;
      reset_type = 2'b01; // subsystem reset
      next_data_out = 8'h01;
    end else if (local_rst) begin
      reset_condition = 1'b1;
      reset_type = 2'b10; // local reset
      next_data_out = 8'h02;
    end else begin
      reset_condition = 1'b0;
      reset_type = 2'b11; // no reset
      next_data_out = (valid && ready) ? data_reg : data_out;
    end
  end
  
  // Handshake state machine
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      valid <= 1'b0;
      transfer_complete <= 1'b0;
      data_reg <= 8'h00;
    end else begin
      if (valid && ready) begin
        // Handshake complete
        valid <= 1'b0;
        transfer_complete <= 1'b1;
      end else if (!valid && !transfer_complete) begin
        // Prepare next transfer
        valid <= 1'b1;
        data_reg <= data_in;
      end else if (!valid && transfer_complete) begin
        // Wait one cycle before starting new transfer
        transfer_complete <= 1'b0;
      end
    end
  end
  
  // Moved and retimed data_out register
  always @(posedge clk) begin
    data_out <= next_data_out;
  end
  
endmodule