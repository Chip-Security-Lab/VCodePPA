//SystemVerilog
module can_loopback_tester(
  input wire clk, rst_n,
  output reg can_tx,
  input wire can_rx,
  output reg test_active, test_passed, test_failed
);
  reg [7:0] test_pattern [0:7];
  reg [2:0] test_state, bit_count, byte_count;
  reg [10:0] test_id;
  
  // Optimized state machine using conditional operators
  always @(posedge clk or negedge rst_n) begin
    // Reset logic using conditional operators
    {test_state, bit_count, byte_count} <= !rst_n ? 9'b0 : 
                                          (test_state == 3'd0) ? {3'd1, 3'b0, 3'b0} :
                                          (test_state == 3'd1) ? {3'd2, bit_count, byte_count} :
                                          (test_state == 3'd2) ? {3'd0, bit_count, byte_count} : // Added for default case
                                          {3'd0, 3'b0, 3'b0};
    
    // Control signals using conditional operators
    {test_active, test_passed, test_failed} <= !rst_n ? 3'b0 :
                                              (test_state == 3'd0) ? {1'b1, test_passed, test_failed} :
                                              {test_active, test_passed, test_failed};
    
    // Test pattern assignments
    test_pattern[0] <= !rst_n ? 8'h55 : test_pattern[0];
    test_pattern[1] <= !rst_n ? 8'hAA : test_pattern[1];
    test_id <= !rst_n ? 11'h555 : test_id;
    
    // CAN TX output using conditional operators
    can_tx <= (test_state == 3'd1) ? 1'b0 : can_tx;
  end
endmodule