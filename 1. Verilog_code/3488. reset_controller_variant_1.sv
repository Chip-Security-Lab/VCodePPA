//SystemVerilog
module reset_controller(
  input clk, master_rst_n, power_stable,
  output reg core_rst_n, periph_rst_n, io_rst_n
);
  reg [1:0] rst_state;
  reg [1:0] next_state;
  reg core_rst_reg, periph_rst_reg, io_rst_reg;
  
  // Retiming: Move next state calculation before combinational logic
  always @(*) begin
    next_state = rst_state;
    
    if (power_stable) begin
      case (rst_state)
        2'b00: next_state = 2'b01;
        2'b01: next_state = 2'b10;
        2'b10: next_state = 2'b11;
        2'b11: next_state = 2'b11;
      endcase
    end
  end
  
  // Retiming: Register core_rst, periph_rst, io_rst earlier in the pipeline
  always @(*) begin
    core_rst_reg = 1'b0;
    periph_rst_reg = 1'b0;
    io_rst_reg = 1'b0;
    
    if (power_stable) begin
      case (next_state)
        2'b01: core_rst_reg = 1'b1;
        2'b10: begin
          core_rst_reg = 1'b1;
          periph_rst_reg = 1'b1;
        end
        2'b11: begin
          core_rst_reg = 1'b1;
          periph_rst_reg = 1'b1;
          io_rst_reg = 1'b1;
        end
        default: begin end
      endcase
    end
  end
  
  // Update state and outputs with retimed registers
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      rst_state <= 2'b00;
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      io_rst_n <= 1'b0;
    end else begin
      rst_state <= next_state;
      core_rst_n <= core_rst_reg;
      periph_rst_n <= periph_rst_reg;
      io_rst_n <= io_rst_reg;
    end
  end
endmodule