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
  
  integer i;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      resp_valid <= 1'b0;
      resp_status <= RESP_OK;
      status_reg <= 32'h0000_0001; // Ready status
      
      for (i = 0; i < 16; i = i + 1)
        debug_regs[i] <= 32'h0;
    end else begin
      resp_valid <= 1'b0;
      
      if (cmd_valid) begin
        case (cmd_in)
          CMD_NOP: begin
            resp_valid <= 1'b1;
            resp_status <= RESP_OK;
          end
          CMD_READ: begin
            if (addr_in[31:28] == 4'h0) begin
              data_out <= debug_regs[addr_in[3:0]];
              resp_valid <= 1'b1;
              resp_status <= RESP_OK;
            end else if (addr_in == 32'hFFFF_FFF0) begin
              data_out <= status_reg;
              resp_valid <= 1'b1;
              resp_status <= RESP_OK;
            end else begin
              resp_valid <= 1'b1;
              resp_status <= RESP_ERROR;
            end
          end
          CMD_WRITE: begin
            if (addr_in[31:28] == 4'h0) begin
              debug_regs[addr_in[3:0]] <= data_in;
              resp_valid <= 1'b1;
              resp_status <= RESP_OK;
            end else begin
              resp_valid <= 1'b1;
              resp_status <= RESP_ERROR;
            end
          end
          CMD_RESET, CMD_STATUS: begin
            resp_valid <= 1'b1;
            resp_status <= RESP_OK;
          end
          default: begin
            resp_valid <= 1'b1;
            resp_status <= RESP_ERROR;
          end
        endcase
      end
    end
  end
endmodule