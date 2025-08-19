//SystemVerilog
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
  
  // Pipeline registers
  reg [ADDR_WIDTH-1:0] addr_pipe_1, addr_pipe_2;
  reg [DATA_WIDTH-1:0] read_data_pipe_1, read_data_pipe_2;
  reg rd_en_pipe_1, rd_en_pipe_2;
  reg wr_en_pipe;
  
  integer i;
  
  // Reset and write logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        registers[i] <= {DATA_WIDTH{1'b0}};
      data_valid <= 1'b0;
      addr_pipe_1 <= {ADDR_WIDTH{1'b0}};
      addr_pipe_2 <= {ADDR_WIDTH{1'b0}};
      read_data_pipe_1 <= {DATA_WIDTH{1'b0}};
      read_data_pipe_2 <= {DATA_WIDTH{1'b0}};
      rd_en_pipe_1 <= 1'b0;
      rd_en_pipe_2 <= 1'b0;
      wr_en_pipe <= 1'b0;
    end else begin
      // First pipeline stage
      addr_pipe_1 <= addr;
      rd_en_pipe_1 <= rd_en;
      wr_en_pipe <= wr_en;
      
      // Write operation
      if (wr_en_pipe)
        registers[addr_pipe_1] <= write_data;
      
      // Read operation - first stage
      if (rd_en_pipe_1)
        read_data_pipe_1 <= registers[addr_pipe_1];
      
      // Second pipeline stage
      addr_pipe_2 <= addr_pipe_1;
      rd_en_pipe_2 <= rd_en_pipe_1;
      read_data_pipe_2 <= read_data_pipe_1;
      
      // Third pipeline stage
      read_data <= read_data_pipe_2;
      data_valid <= rd_en_pipe_2;
    end
  end
endmodule