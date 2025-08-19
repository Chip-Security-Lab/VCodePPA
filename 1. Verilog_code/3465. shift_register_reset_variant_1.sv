//SystemVerilog IEEE 1364-2005
module shift_register_reset #(parameter WIDTH = 16)(
  input clk, reset, shift_en, data_in,
  output reg [WIDTH-1:0] shift_data
);
  // Pipeline stage 1 signals
  reg [1:0] control_stage1;
  reg data_in_stage1;
  
  // Pipeline stage 2 signals
  reg [1:0] control_stage2;
  reg data_in_stage2;
  reg [WIDTH-1:0] shift_data_stage2;
  
  // Pipeline stage 3 signals
  reg [WIDTH-1:0] shift_data_next;
  
  // Pipeline stage 1: Control logic
  always @(posedge clk) begin
    if (reset) begin
      control_stage1 <= 2'b10; // Reset state
      data_in_stage1 <= 1'b0;
    end else begin
      control_stage1 <= {reset, shift_en};
      data_in_stage1 <= data_in;
    end
  end
  
  // Pipeline stage 2: Prepare next state
  always @(posedge clk) begin
    if (reset) begin
      control_stage2 <= 2'b10;
      data_in_stage2 <= 1'b0;
      shift_data_stage2 <= shift_data;
    end else begin
      control_stage2 <= control_stage1;
      data_in_stage2 <= data_in_stage1;
      shift_data_stage2 <= shift_data;
    end
  end
  
  // Pipeline stage 3: Calculate next shift data value
  always @(posedge clk) begin
    if (reset) begin
      shift_data <= {WIDTH{1'b0}};
    end else begin
      shift_data <= shift_data_next;
    end
  end
  
  // Combinational logic to determine next shift_data value
  always @(*) begin
    case(control_stage2)
      2'b10, 2'b11: shift_data_next = {WIDTH{1'b0}};      // reset active
      2'b01:        shift_data_next = {shift_data_stage2[WIDTH-2:0], data_in_stage2}; // shift
      2'b00:        shift_data_next = shift_data_stage2;  // no change
      default:      shift_data_next = shift_data_stage2;
    endcase
  end
endmodule