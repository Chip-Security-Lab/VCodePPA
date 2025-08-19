//SystemVerilog
module multi_level_intr_ctrl(
  input clk, reset_n,
  input [15:0] intr_source,
  input [1:0] level_sel,
  output reg [3:0] intr_id,
  output reg active
);
  // Optimize priority encoder with parallel logic
  function [1:0] find_first_bit_opt;
    input [3:0] vec;
    begin
      casez(vec)
        4'b???1: find_first_bit_opt = 2'b00;
        4'b??10: find_first_bit_opt = 2'b01;
        4'b?100: find_first_bit_opt = 2'b10;
        4'b1000: find_first_bit_opt = 2'b11;
        default: find_first_bit_opt = 2'b00;
      endcase
    end
  endfunction
  
  // Register inputs to reduce input path delay
  reg [15:0] intr_source_r;
  reg [1:0] level_sel_r;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      intr_source_r <= 16'd0;
      level_sel_r <= 2'd0;
    end else begin
      intr_source_r <= intr_source;
      level_sel_r <= level_sel;
    end
  end
  
  // Optimized priority encoder outputs
  reg [1:0] group_ids [0:3];
  
  // Check validity with single reduction operations - move to registers
  reg [3:0] group_valid;
  
  // Pre-compute these values and register them
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      group_ids[3] <= 2'd0;
      group_ids[2] <= 2'd0;
      group_ids[1] <= 2'd0;
      group_ids[0] <= 2'd0;
      group_valid <= 4'd0;
    end else begin
      group_ids[3] <= find_first_bit_opt(intr_source_r[15:12]);
      group_ids[2] <= find_first_bit_opt(intr_source_r[11:8]);
      group_ids[1] <= find_first_bit_opt(intr_source_r[7:4]);
      group_ids[0] <= find_first_bit_opt(intr_source_r[3:0]);
      
      group_valid[3] <= |intr_source_r[15:12];
      group_valid[2] <= |intr_source_r[11:8];
      group_valid[1] <= |intr_source_r[7:4];
      group_valid[0] <= |intr_source_r[3:0];
    end
  end
  
  // Compute active status 
  wire any_intr_active = |group_valid;
  
  // Priority selection logic - now working with registered values
  reg [3:0] next_intr_id;
  reg next_active;
  
  always @(*) begin
    // Default values
    next_intr_id = 4'b0000;
    next_active = any_intr_active;
    
    casez({level_sel_r, group_valid})
      // Level 0 priority order: high > med > low > sys
      {2'b00, 4'b1???}: next_intr_id = {2'b11, group_ids[3]};
      {2'b00, 4'b01??}: next_intr_id = {2'b10, group_ids[2]};
      {2'b00, 4'b001?}: next_intr_id = {2'b01, group_ids[1]};
      {2'b00, 4'b0001}: next_intr_id = {2'b00, group_ids[0]};
      
      // Level 1 priority order: med > low > sys > high
      {2'b01, 4'b?1??}: next_intr_id = {2'b10, group_ids[2]};
      {2'b01, 4'b?01?}: next_intr_id = {2'b01, group_ids[1]};
      {2'b01, 4'b?001}: next_intr_id = {2'b00, group_ids[0]};
      {2'b01, 4'b1???}: next_intr_id = {2'b11, group_ids[3]};
      
      // Level 2 priority order: low > sys > high > med
      {2'b10, 4'b??1?}: next_intr_id = {2'b01, group_ids[1]};
      {2'b10, 4'b??01}: next_intr_id = {2'b00, group_ids[0]};
      {2'b10, 4'b1???}: next_intr_id = {2'b11, group_ids[3]};
      {2'b10, 4'b01??}: next_intr_id = {2'b10, group_ids[2]};
      
      // Level 3 priority order: sys > high > med > low
      {2'b11, 4'b???1}: next_intr_id = {2'b00, group_ids[0]};
      {2'b11, 4'b1???}: next_intr_id = {2'b11, group_ids[3]};
      {2'b11, 4'b01??}: next_intr_id = {2'b10, group_ids[2]};
      {2'b11, 4'b001?}: next_intr_id = {2'b01, group_ids[1]};
      
      default: next_intr_id = 4'd0;
    endcase
  end
  
  // Register outputs with synchronous reset
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      intr_id <= 4'd0;
      active <= 1'b0;
    end else begin
      intr_id <= next_intr_id;
      active <= next_active;
    end
  end
endmodule