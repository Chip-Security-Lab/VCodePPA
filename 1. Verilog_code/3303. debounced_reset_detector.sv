module debounced_reset_detector #(parameter DEBOUNCE_CYCLES = 8)(
  input clock, external_reset_n, power_on_reset_n,
  output reg reset_active, 
  output reg [1:0] reset_source
);
  reg [3:0] ext_counter = 0, por_counter = 0;
  
  always @(posedge clock) begin
    ext_counter <= external_reset_n ? 0 : (ext_counter == DEBOUNCE_CYCLES ? 
                   DEBOUNCE_CYCLES : ext_counter + 1);
    por_counter <= power_on_reset_n ? 0 : (por_counter == DEBOUNCE_CYCLES ? 
                   DEBOUNCE_CYCLES : por_counter + 1);
    reset_active <= (ext_counter == DEBOUNCE_CYCLES) || 
                   (por_counter == DEBOUNCE_CYCLES);
    reset_source <= (por_counter == DEBOUNCE_CYCLES) ? 2'b01 :
                   (ext_counter == DEBOUNCE_CYCLES) ? 2'b10 : 2'b00;
  end
endmodule