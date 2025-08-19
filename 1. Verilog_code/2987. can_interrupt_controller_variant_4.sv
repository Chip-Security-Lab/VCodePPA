//SystemVerilog
module can_interrupt_controller(
  input wire clk, rst_n,
  input wire tx_done, rx_done, error_detected, bus_off,
  input wire [3:0] interrupt_mask,
  output reg interrupt,
  output reg [3:0] interrupt_status
);
  reg [3:0] pending_interrupts;
  
  // Register input signals directly
  reg tx_done_reg, rx_done_reg, error_detected_reg, bus_off_reg;
  
  // Previous state registers
  reg prev_tx_done, prev_rx_done, prev_error, prev_bus_off;
  
  // Edge detection signals (combinational)
  wire tx_edge, rx_edge, error_edge, bus_off_edge;
  
  // Input signal registration for improved timing path
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_done_reg <= 1'b0;
      rx_done_reg <= 1'b0;
      error_detected_reg <= 1'b0;
      bus_off_reg <= 1'b0;
    end else begin
      tx_done_reg <= tx_done;
      rx_done_reg <= rx_done;
      error_detected_reg <= error_detected;
      bus_off_reg <= bus_off;
    end
  end
  
  // Previous state registration for edge detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_tx_done <= 1'b0;
      prev_rx_done <= 1'b0;
      prev_error <= 1'b0;
      prev_bus_off <= 1'b0;
    end else begin
      prev_tx_done <= tx_done_reg;
      prev_rx_done <= rx_done_reg;
      prev_error <= error_detected_reg;
      prev_bus_off <= bus_off_reg;
    end
  end
  
  // Edge detection using registered inputs (combinational logic)
  assign tx_edge = tx_done_reg & ~prev_tx_done;
  assign rx_edge = rx_done_reg & ~prev_rx_done;
  assign error_edge = error_detected_reg & ~prev_error;
  assign bus_off_edge = bus_off_reg & ~prev_bus_off;
  
  // Pending interrupts management
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_interrupts <= 4'b0000;
    end else begin
      if (tx_edge) pending_interrupts[0] <= 1'b1;
      if (rx_edge) pending_interrupts[1] <= 1'b1;
      if (error_edge) pending_interrupts[2] <= 1'b1;
      if (bus_off_edge) pending_interrupts[3] <= 1'b1;
    end
  end
  
  // Interrupt status update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      interrupt_status <= 4'b0000;
    end else begin
      interrupt_status <= pending_interrupts;
    end
  end
  
  // Interrupt generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      interrupt <= 1'b0;
    end else begin
      interrupt <= |(pending_interrupts & interrupt_mask);
    end
  end
  
endmodule