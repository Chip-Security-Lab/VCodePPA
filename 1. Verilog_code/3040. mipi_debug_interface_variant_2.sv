//SystemVerilog
module mipi_debug_interface (
  input wire clk, reset_n,
  input wire [3:0] cmd_in,
  input wire [31:0] addr_in,
  input wire [31:0] data_in,
  input wire cmd_valid,
  output reg [31:0] data_out,
  output reg resp_valid,
  output reg [1:0] resp_status
);
  localparam CMD_NOP = 4'h0, CMD_READ = 4'h1, CMD_WRITE = 4'h2;
  localparam CMD_RESET = 4'h3, CMD_STATUS = 4'h4;
  localparam RESP_OK = 2'b00, RESP_ERROR = 2'b01, RESP_BUSY = 2'b10;
  
  reg [31:0] status_reg;
  reg [31:0] debug_regs [0:15];
  reg [3:0] state;
  
  wire is_debug_addr = ~|addr_in[31:28];
  wire is_status_addr = &addr_in;
  wire [3:0] reg_index = addr_in[3:0];
  wire is_valid_cmd = (cmd_in <= CMD_STATUS);
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      resp_valid <= 1'b0;
      resp_status <= RESP_OK;
      status_reg <= 32'h0000_0001;
      
      for (integer i = 0; i < 16; i = i + 1)
        debug_regs[i] <= 32'h0;
    end else begin
      resp_valid <= 1'b0;
      
      if (cmd_valid) begin
        case (1'b1)
          (cmd_in == CMD_NOP): begin
            {resp_valid, resp_status} <= {1'b1, RESP_OK};
          end
          (cmd_in == CMD_READ): begin
            data_out <= is_debug_addr ? debug_regs[reg_index] : 
                      is_status_addr ? status_reg : 32'h0;
            {resp_valid, resp_status} <= {1'b1, is_debug_addr | is_status_addr ? RESP_OK : RESP_ERROR};
          end
          (cmd_in == CMD_WRITE): begin
            if (is_debug_addr) debug_regs[reg_index] <= data_in;
            {resp_valid, resp_status} <= {1'b1, is_debug_addr ? RESP_OK : RESP_ERROR};
          end
          (cmd_in == CMD_RESET || cmd_in == CMD_STATUS): begin
            {resp_valid, resp_status} <= {1'b1, RESP_OK};
          end
          default: begin
            {resp_valid, resp_status} <= {1'b1, RESP_ERROR};
          end
        endcase
      end
    end
  end
endmodule