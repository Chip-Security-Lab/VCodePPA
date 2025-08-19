module mipi_rffe_register_file #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  input wire clk, reset_n,
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [DATA_WIDTH-1:0] write_data,
  input wire wr_en, rd_en,
  output reg [DATA_WIDTH-1:0] read_data,
  output reg data_valid
);
  // Register array
  reg [DATA_WIDTH-1:0] registers [(1<<ADDR_WIDTH)-1:0];
  
  integer i;
  
  // Reset and write logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        registers[i] <= {DATA_WIDTH{1'b0}};
      data_valid <= 1'b0;
    end else begin
      data_valid <= 1'b0;
      
      if (wr_en)
        registers[addr] <= write_data;
      
      if (rd_en) begin
        read_data <= registers[addr];
        data_valid <= 1'b1;
      end
    end
  end
endmodule