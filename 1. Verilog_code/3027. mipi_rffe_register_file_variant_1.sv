//SystemVerilog
module mipi_rffe_register_file #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  input wire clk,
  input wire reset_n,
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [DATA_WIDTH-1:0] write_data,
  input wire wr_en,
  input wire rd_en,
  output reg [DATA_WIDTH-1:0] read_data,
  output reg data_valid
);

  // Register array with pipeline stages
  reg [DATA_WIDTH-1:0] registers [(1<<ADDR_WIDTH)-1:0];
  reg [DATA_WIDTH-1:0] read_data_pipe;
  reg data_valid_pipe;
  
  // Address processing pipeline
  wire addr_valid;
  wire [(1<<ADDR_WIDTH)-1:0] addr_decode;
  reg [(1<<ADDR_WIDTH)-1:0] addr_decode_reg;
  
  // Data processing pipeline
  wire [DATA_WIDTH-1:0] read_data_next;
  wire data_valid_next;
  
  // Address validation stage
  assign addr_valid = addr < (1<<ADDR_WIDTH);
  
  // Address decoding stage
  assign addr_decode = addr_valid ? (1'b1 << addr) : {(1<<ADDR_WIDTH){1'b0}};
  
  // Read data computation stage
  assign read_data_next = addr_valid ? registers[addr] : {DATA_WIDTH{1'b0}};
  assign data_valid_next = rd_en && addr_valid;
  
  // Main pipeline control
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_decode_reg <= {(1<<ADDR_WIDTH){1'b0}};
      read_data_pipe <= {DATA_WIDTH{1'b0}};
      data_valid_pipe <= 1'b0;
      read_data <= {DATA_WIDTH{1'b0}};
      data_valid <= 1'b0;
    end else begin
      // Pipeline stage 1: Address decode
      addr_decode_reg <= addr_decode;
      
      // Pipeline stage 2: Read data and valid
      read_data_pipe <= read_data_next;
      data_valid_pipe <= data_valid_next;
      
      // Pipeline stage 3: Output
      read_data <= read_data_pipe;
      data_valid <= data_valid_pipe;
      
      // Write operation (combinational)
      if (wr_en && addr_valid) begin
        registers[addr] <= write_data;
      end
    end
  end

  // Reset registers with optimized timing
  genvar i;
  generate
    for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin : reset_regs
      always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
          registers[i] <= {DATA_WIDTH{1'b0}};
        end
      end
    end
  endgenerate

endmodule