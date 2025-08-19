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
  
  // Pipeline stage 1: Input buffering
  reg [ADDR_WIDTH-1:0] addr_stage1;
  reg wr_en_stage1, rd_en_stage1;
  reg [DATA_WIDTH-1:0] write_data_stage1;
  
  // Pipeline stage 2: Register access
  reg [ADDR_WIDTH-1:0] addr_stage2;
  reg wr_en_stage2, rd_en_stage2;
  reg [DATA_WIDTH-1:0] write_data_stage2;
  reg [DATA_WIDTH-1:0] read_data_stage2;
  reg data_valid_stage2;
  
  // Pipeline stage 3: Output buffering
  reg [DATA_WIDTH-1:0] read_data_stage3;
  reg data_valid_stage3;
  
  // Reset logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      for (integer i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        registers[i] <= {DATA_WIDTH{1'b0}};
      
      // Stage 1 reset
      addr_stage1 <= {ADDR_WIDTH{1'b0}};
      wr_en_stage1 <= 1'b0;
      rd_en_stage1 <= 1'b0;
      write_data_stage1 <= {DATA_WIDTH{1'b0}};
      
      // Stage 2 reset
      addr_stage2 <= {ADDR_WIDTH{1'b0}};
      wr_en_stage2 <= 1'b0;
      rd_en_stage2 <= 1'b0;
      write_data_stage2 <= {DATA_WIDTH{1'b0}};
      read_data_stage2 <= {DATA_WIDTH{1'b0}};
      data_valid_stage2 <= 1'b0;
      
      // Stage 3 reset
      read_data_stage3 <= {DATA_WIDTH{1'b0}};
      data_valid_stage3 <= 1'b0;
      
      // Output reset
      read_data <= {DATA_WIDTH{1'b0}};
      data_valid <= 1'b0;
    end else begin
      // Stage 1: Input buffering
      addr_stage1 <= addr;
      wr_en_stage1 <= wr_en;
      rd_en_stage1 <= rd_en;
      write_data_stage1 <= write_data;
      
      // Stage 2: Register access
      addr_stage2 <= addr_stage1;
      wr_en_stage2 <= wr_en_stage1;
      rd_en_stage2 <= rd_en_stage1;
      write_data_stage2 <= write_data_stage1;
      
      // Write operation
      if (wr_en_stage1)
        registers[addr_stage1] <= write_data_stage1;
      
      // Read operation
      if (rd_en_stage1) begin
        read_data_stage2 <= registers[addr_stage1];
        data_valid_stage2 <= 1'b1;
      end else begin
        data_valid_stage2 <= 1'b0;
      end
      
      // Stage 3: Output buffering
      read_data_stage3 <= read_data_stage2;
      data_valid_stage3 <= data_valid_stage2;
      
      // Output
      read_data <= read_data_stage3;
      data_valid <= data_valid_stage3;
    end
  end
endmodule