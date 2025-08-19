module reset_sequence_gen(
  input clk, trigger_reset, config_mode,
  input [1:0] sequence_select,
  output reg core_rst, periph_rst, mem_rst, io_rst,
  output reg sequence_done
);
  reg [2:0] seq_counter = 0;
  reg seq_active = 0;
  
  always @(posedge clk) begin
    if (trigger_reset && !seq_active) begin
      seq_active <= 1; seq_counter <= 0;
      sequence_done <= 0;
    end else if (seq_active) begin
      seq_counter <= seq_counter + 1;
      if (seq_counter == 7) begin
        seq_active <= 0; sequence_done <= 1;
      end
    end
    
    case (sequence_select)
      2'b00: {core_rst, periph_rst, mem_rst, io_rst} <= seq_active ? 
              (seq_counter < 2 ? 4'b1111 : (seq_counter < 4 ? 4'b0111 : 
               (seq_counter < 6 ? 4'b0011 : 4'b0000))) : 4'b0000;
      2'b01: {core_rst, periph_rst, mem_rst, io_rst} <= seq_active ?
              (seq_counter < 3 ? 4'b1111 : (seq_counter < 5 ? 4'b0101 : 4'b0000)) : 4'b0000;
      default: {core_rst, periph_rst, mem_rst, io_rst} <= {4{seq_active}};
    endcase
  end
endmodule