//SystemVerilog
//IEEE 1364-2005 Verilog
module tristate_bus_arbiter(
  input wire clk, reset,
  input wire [3:0] req,
  output wire [3:0] grant,
  inout wire [7:0] data_bus,
  input wire [7:0] data_in [3:0],
  output wire [7:0] data_out
);
  reg [3:0] grant_r;
  reg [1:0] current;
  
  // Pipeline registers for data path
  reg [7:0] data_selected_stage1;
  reg [7:0] data_selected_stage2;
  reg [3:0] grant_r_pipe;
  
  // Grant signal assignment
  assign grant = grant_r;
  
  // First stage selection - break long mux chain into two stages
  always @(*) begin
    case(grant_r[1:0])
      2'b01: data_selected_stage1 = data_in[0];
      2'b10: data_selected_stage1 = data_in[1];
      default: data_selected_stage1 = 8'bz;
    endcase
  end
  
  // Second stage selection with Karatsuba multiplier for data processing
  wire [7:0] karatsuba_result;
  
  // Use 16-bit Karatsuba multiplier to process data when needed
  karatsuba_multiplier_16bit km1 (
    .a({8'b0, data_selected_stage1}),
    .b({8'b0, data_in[3]}),
    .product(karatsuba_result)
  );
  
  always @(*) begin
    case(grant_r[3:2]) 
      2'b01: data_selected_stage2 = data_in[2];
      2'b10: data_selected_stage2 = karatsuba_result; // Use Karatsuba result
      default: data_selected_stage2 = data_selected_stage1;
    endcase
  end
  
  // Tristate bus driver with pipeline register
  reg [7:0] data_out_r;
  reg bus_drive_en;
  
  always @(posedge clk) begin
    data_out_r <= data_selected_stage2;
    bus_drive_en <= |grant_r;
    grant_r_pipe <= grant_r;
  end
  
  // Drive bus only when a device is granted access
  assign data_bus = bus_drive_en ? data_out_r : 8'bz;
  assign data_out = data_bus;
  
  // Arbiter control logic
  always @(posedge clk) begin
    if (reset) begin
      grant_r <= 4'h0;
      current <= 2'b00;
    end else begin
      if (req[current]) grant_r <= (4'h1 << current);
      else grant_r <= 4'h0;
      current <= current + 1;
    end
  end
endmodule

// 16-bit Karatsuba multiplier implementation
module karatsuba_multiplier_16bit(
  input wire [15:0] a,
  input wire [15:0] b,
  output wire [15:0] product
);
  // Split inputs into high and low 8-bit parts
  wire [7:0] a_high, a_low, b_high, b_low;
  assign a_high = a[15:8];
  assign a_low = a[7:0];
  assign b_high = b[15:8];
  assign b_low = b[7:0];
  
  // Karatsuba algorithm components
  wire [15:0] z0, z1, z2;
  wire [8:0] a_sum, b_sum;  // 9-bit to handle potential carry
  wire [17:0] z1_term;      // (a_high+a_low)*(b_high+b_low) can be up to 18 bits
  
  // Calculate a_high + a_low and b_high + b_low
  assign a_sum = a_high + a_low;
  assign b_sum = b_high + b_low;
  
  // Calculate the three Karatsuba terms
  // z0 = a_low * b_low
  // z2 = a_high * b_high
  // z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2
  
  // Implement submultipliers using Karatsuba approach recursively
  karatsuba_multiplier_8bit km_low(
    .a(a_low),
    .b(b_low),
    .product(z0[15:0])
  );
  
  karatsuba_multiplier_8bit km_high(
    .a(a_high),
    .b(b_high),
    .product(z2[15:0])
  );
  
  karatsuba_multiplier_9bit km_mid(
    .a(a_sum),
    .b(b_sum),
    .product(z1_term[17:0])
  );
  
  // z1 = z1_term - z0 - z2
  assign z1 = z1_term[15:0] - z0 - z2;
  
  // Final result calculation: z2 * 2^16 + z1 * 2^8 + z0
  // For 16-bit output, we truncate/select relevant bits
  wire [31:0] full_result;
  assign full_result = {z2, 16'b0} + {8'b0, z1, 8'b0} + z0;
  assign product = full_result[15:0];
endmodule

// 8-bit Karatsuba multiplier implementation (for recursive use)
module karatsuba_multiplier_8bit(
  input wire [7:0] a,
  input wire [7:0] b,
  output wire [15:0] product
);
  // Split inputs into high and low 4-bit parts
  wire [3:0] a_high, a_low, b_high, b_low;
  assign a_high = a[7:4];
  assign a_low = a[3:0];
  assign b_high = b[7:4];
  assign b_low = b[3:0];
  
  // Karatsuba algorithm components
  wire [7:0] z0, z1, z2;
  wire [4:0] a_sum, b_sum;  // 5-bit to handle carry
  wire [9:0] z1_term;       // Wider to prevent overflow
  
  // Calculate a_high + a_low and b_high + b_low
  assign a_sum = a_high + a_low;
  assign b_sum = b_high + b_low;
  
  // Calculate the three Karatsuba terms
  assign z0 = a_low * b_low;
  assign z2 = a_high * b_high;
  assign z1_term = a_sum * b_sum;
  assign z1 = z1_term - z0 - z2;
  
  // Final result calculation: z2 * 2^8 + z1 * 2^4 + z0
  wire [15:0] full_result;
  assign full_result = {z2, 8'b0} + {4'b0, z1, 4'b0} + {8'b0, z0};
  assign product = full_result;
endmodule

// 9-bit Karatsuba multiplier for the middle term calculation
module karatsuba_multiplier_9bit(
  input wire [8:0] a,
  input wire [8:0] b,
  output wire [17:0] product
);
  // Split inputs into high and low parts (5-bit high, 4-bit low)
  wire [4:0] a_high, b_high;
  wire [3:0] a_low, b_low;
  
  assign a_high = a[8:4];
  assign a_low = a[3:0];
  assign b_high = b[8:4];
  assign b_low = b[3:0];
  
  // Karatsuba algorithm components
  wire [7:0] z0;    // a_low * b_low (4-bit * 4-bit = 8-bit)
  wire [9:0] z2;    // a_high * b_high (5-bit * 5-bit = 10-bit)
  wire [9:0] z1;    // Cross-term
  
  wire [5:0] a_sum, b_sum;  // 6-bit for sum
  wire [11:0] z1_term;
  
  // Calculate sums
  assign a_sum = a_high + {1'b0, a_low};
  assign b_sum = b_high + {1'b0, b_low};
  
  // Calculate Karatsuba terms
  assign z0 = a_low * b_low;
  assign z2 = a_high * b_high;
  assign z1_term = a_sum * b_sum;
  assign z1 = z1_term - {2'b0, z0} - z2;
  
  // Final result calculation
  wire [17:0] full_result;
  assign full_result = {z2, 8'b0} + {4'b0, z1, 4'b0} + {10'b0, z0};
  assign product = full_result;
endmodule