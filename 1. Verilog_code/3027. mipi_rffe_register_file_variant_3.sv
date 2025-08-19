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
  
  // Pipeline stage 1 signals
  reg [ADDR_WIDTH-1:0] addr_stage1;
  reg [DATA_WIDTH-1:0] write_data_stage1;
  reg wr_en_stage1, rd_en_stage1;
  reg [DATA_WIDTH-1:0] barrel_shifted_data_stage1;
  
  // Pipeline stage 2 signals
  reg [DATA_WIDTH-1:0] barrel_shifted_data_stage2;
  reg rd_en_stage2;
  
  // Barrel shifter implementation
  generate
    genvar i;
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : barrel_shift
      assign barrel_shifted_data_stage1[i] = (addr_stage1 < DATA_WIDTH) ? 
        ((i + addr_stage1) < DATA_WIDTH ? registers[addr_stage1][i + addr_stage1] : 1'b0) : 1'b0;
    end
  endgenerate
  
  // Pipeline stage 1: Register file access and barrel shift
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      for (integer i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        registers[i] <= {DATA_WIDTH{1'b0}};
      addr_stage1 <= {ADDR_WIDTH{1'b0}};
      write_data_stage1 <= {DATA_WIDTH{1'b0}};
      wr_en_stage1 <= 1'b0;
      rd_en_stage1 <= 1'b0;
    end else begin
      addr_stage1 <= addr;
      write_data_stage1 <= write_data;
      wr_en_stage1 <= wr_en;
      rd_en_stage1 <= rd_en;
      
      if (wr_en_stage1)
        registers[addr_stage1] <= write_data_stage1;
    end
  end
  
  // Pipeline stage 2: Data output
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      barrel_shifted_data_stage2 <= {DATA_WIDTH{1'b0}};
      rd_en_stage2 <= 1'b0;
      read_data <= {DATA_WIDTH{1'b0}};
      data_valid <= 1'b0;
    end else begin
      barrel_shifted_data_stage2 <= barrel_shifted_data_stage1;
      rd_en_stage2 <= rd_en_stage1;
      
      if (rd_en_stage2) begin
        read_data <= barrel_shifted_data_stage2;
        data_valid <= 1'b1;
      end else begin
        data_valid <= 1'b0;
      end
    end
  end
endmodule