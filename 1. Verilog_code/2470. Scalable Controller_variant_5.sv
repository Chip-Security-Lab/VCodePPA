//SystemVerilog
module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input wire clk, rst,
  input wire [SOURCES-1:0] requests,
  output reg [ID_WIDTH-1:0] grant_id,
  output reg grant_valid
);
  
  reg [SOURCES-1:0] requests_reg;
  reg [ID_WIDTH-1:0] priority_id;
  reg priority_valid;
  integer i;
  
  // Register input requests to break timing path
  always @(posedge clk) begin
    if (rst) begin
      requests_reg <= {SOURCES{1'b0}};
    end else begin
      requests_reg <= requests;
    end
  end
  
  // Calculate priority logic in first stage
  always @(posedge clk) begin
    if (rst) begin
      priority_id <= {ID_WIDTH{1'b0}};
      priority_valid <= 1'b0;
    end else begin
      priority_valid <= |requests_reg;
      priority_id <= {ID_WIDTH{1'b0}};
      
      // 将for循环转换为while循环
      i = 0;
      while (i < SOURCES) begin
        if (requests_reg[i]) priority_id <= i[ID_WIDTH-1:0];
        i = i + 1;
      end
    end
  end
  
  // Output stage register
  always @(posedge clk) begin
    if (rst) begin
      grant_id <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
    end else begin
      grant_id <= priority_id;
      grant_valid <= priority_valid;
    end
  end
  
endmodule