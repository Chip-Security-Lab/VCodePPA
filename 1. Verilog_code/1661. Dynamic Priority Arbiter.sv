module dynamic_priority_arbiter(
  input wire clk, rst_n,
  input wire [7:0] requests,
  input wire [23:0] dynamic_priority, // Flatten: 8 x 3-bit priorities
  output reg [7:0] grants
);
  wire [2:0] priority_array [0:7];
  reg [7:0] masked_req;
  integer i, j, highest_pri;
  reg [2:0] current_pri;
  
  // Extract individual priorities
  genvar g;
  generate
    for (g = 0; g < 8; g = g + 1) begin: priority_extract
      assign priority_array[g] = dynamic_priority[g*3 +: 3];
    end
  endgenerate
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) grants <= 8'b0;
    else begin
      grants <= 8'b0;
      highest_pri = 0;
      current_pri = 0;
      
      // Find highest priority
      for (i = 0; i < 8; i = i + 1) begin
        if (requests[i] && (priority_array[i] > current_pri)) begin
          current_pri = priority_array[i];
          highest_pri = i;
        end
      end
      
      // Grant to highest priority request
      if (|requests) begin
        grants[highest_pri] <= 1'b1;
      end
    end
  end
endmodule