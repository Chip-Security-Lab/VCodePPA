//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;
  
  // Han-Carlson adder signals
  wire [7:0] p, g;  // Propagate and generate signals
  
  // Generate p and g signals for Han-Carlson adder
  assign p = timeout ^ 8'd1;  // Propagate = a XOR b
  assign g = timeout & 8'd1;  // Generate = a AND b
  
  // Pipeline registers for adder stages
  reg [7:0] p_s1_r, g_s1_r;
  reg [7:0] p_s3_r, g_s3_r;
  
  // Stage 1: Pre-processing
  wire [7:0] p_s1, g_s1;
  assign p_s1 = p;
  assign g_s1 = g;
  
  // Stage 2: First level of prefix computation (even bits)
  wire [7:0] p_s2, g_s2;
  assign p_s2[0] = p_s1_r[0];
  assign g_s2[0] = g_s1_r[0];
  
  assign p_s2[2] = p_s1_r[2] & p_s1_r[1];
  assign g_s2[2] = g_s1_r[2] | (p_s1_r[2] & g_s1_r[1]);
  
  assign p_s2[4] = p_s1_r[4] & p_s1_r[3];
  assign g_s2[4] = g_s1_r[4] | (p_s1_r[4] & g_s1_r[3]);
  
  assign p_s2[6] = p_s1_r[6] & p_s1_r[5];
  assign g_s2[6] = g_s1_r[6] | (p_s1_r[6] & g_s1_r[5]);
  
  assign p_s2[1] = p_s1_r[1];
  assign g_s2[1] = g_s1_r[1];
  
  assign p_s2[3] = p_s1_r[3];
  assign g_s2[3] = g_s1_r[3];
  
  assign p_s2[5] = p_s1_r[5];
  assign g_s2[5] = g_s1_r[5];
  
  assign p_s2[7] = p_s1_r[7];
  assign g_s2[7] = g_s1_r[7];
  
  // Stage 3: Second level of prefix computation (even bits)
  wire [7:0] p_s3, g_s3;
  assign p_s3[0] = p_s2[0];
  assign g_s3[0] = g_s2[0];
  
  assign p_s3[2] = p_s2[2];
  assign g_s3[2] = g_s2[2];
  
  assign p_s3[4] = p_s2[4] & p_s2[2];
  assign g_s3[4] = g_s2[4] | (p_s2[4] & g_s2[2]);
  
  assign p_s3[6] = p_s2[6] & p_s2[4];
  assign g_s3[6] = g_s2[6] | (p_s2[6] & g_s2[4]);
  
  assign p_s3[1] = p_s2[1];
  assign g_s3[1] = g_s2[1];
  
  assign p_s3[3] = p_s2[3];
  assign g_s3[3] = g_s2[3];
  
  assign p_s3[5] = p_s2[5];
  assign g_s3[5] = g_s2[5];
  
  assign p_s3[7] = p_s2[7];
  assign g_s3[7] = g_s2[7];
  
  // Stage 4: Compute odd bits
  wire [7:0] p_s4, g_s4;
  assign p_s4[0] = p_s3_r[0];
  assign g_s4[0] = g_s3_r[0];
  
  assign p_s4[2] = p_s3_r[2];
  assign g_s4[2] = g_s3_r[2];
  
  assign p_s4[4] = p_s3_r[4];
  assign g_s4[4] = g_s3_r[4];
  
  assign p_s4[6] = p_s3_r[6];
  assign g_s4[6] = g_s3_r[6];
  
  assign p_s4[1] = p_s3_r[1] & p_s3_r[0];
  assign g_s4[1] = g_s3_r[1] | (p_s3_r[1] & g_s3_r[0]);
  
  assign p_s4[3] = p_s3_r[3] & p_s3_r[2];
  assign g_s4[3] = g_s3_r[3] | (p_s3_r[3] & g_s3_r[2]);
  
  assign p_s4[5] = p_s3_r[5] & p_s3_r[4];
  assign g_s4[5] = g_s3_r[5] | (p_s3_r[5] & g_s3_r[4]);
  
  assign p_s4[7] = p_s3_r[7] & p_s3_r[6];
  assign g_s4[7] = g_s3_r[7] | (p_s3_r[7] & g_s3_r[6]);
  
  // Stage 5: Final sum computation
  wire [7:0] carry;
  assign carry[0] = 1'b0; // Initial carry is 0
  assign carry[7:1] = g_s4[6:0];
  
  wire [7:0] sum = p_s1_r ^ carry;
  
  // Pipeline control signals
  reg checking_d1, checking_d2;
  reg [3:0] reset_dst_d1, reset_dst_d2;
  reg [7:0] timeout_max_check;
  
  always @(posedge clk) begin
    // Adder pipeline registers
    p_s1_r <= p_s1;
    g_s1_r <= g_s1;
    p_s3_r <= p_s3;
    g_s3_r <= g_s3;
    
    // Control pipeline
    checking_d1 <= checking;
    checking_d2 <= checking_d1;
    reset_dst_d1 <= reset_dst;
    reset_dst_d2 <= reset_dst_d1;
    
    // Main control logic
    reset_src_d <= reset_src;
    
    if (reset_src && !reset_src_d) begin
      checking <= 1'b1;
      timeout <= 8'd0;
      timeout_max_check <= 8'd0;
      propagation_error <= 1'b0;
    end else if (checking_d2) begin
      timeout <= sum;  // Use Han-Carlson adder result (pipelined)
      timeout_max_check <= (sum == 8'hFF) ? 8'hFF : timeout_max_check;
      
      if (&reset_dst_d2)
        checking <= 1'b0;
      else if (timeout_max_check == 8'hFF) begin
        propagation_error <= 1'b1;
        checking <= 1'b0;
      end
    end
  end
endmodule