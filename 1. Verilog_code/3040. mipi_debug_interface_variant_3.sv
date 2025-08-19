//SystemVerilog
// Top level module
module mipi_debug_interface (
  input wire clk,
  input wire reset_n,
  input wire [3:0] cmd_in,
  input wire [31:0] addr_in,
  input wire [31:0] data_in,
  input wire cmd_valid,
  output wire [31:0] data_out,
  output wire resp_valid,
  output wire [1:0] resp_status
);

  wire [1:0] cmd_type;
  wire cmd_valid_decoded;
  wire addr_valid;
  wire [31:0] reg_data_out;
  wire [31:0] status_data_out;

  reg [31:0] addr_in_pipe;
  reg [31:0] data_in_pipe;
  reg cmd_valid_pipe;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      addr_in_pipe <= 32'h0;
      data_in_pipe <= 32'h0;
      cmd_valid_pipe <= 1'b0;
    end else begin
      addr_in_pipe <= addr_in;
      data_in_pipe <= data_in;
      cmd_valid_pipe <= cmd_valid;
    end
  end

  assign addr_valid = (addr_in_pipe[31:28] == 4'h0) || (addr_in_pipe == 32'hFFFF_FFF0);

  cmd_decoder cmd_decoder_inst (
    .clk(clk),
    .reset_n(reset_n),
    .cmd_in(cmd_in),
    .cmd_valid(cmd_valid_pipe),
    .cmd_type(cmd_type),
    .cmd_valid_out(cmd_valid_decoded)
  );

  reg_file reg_file_inst (
    .clk(clk),
    .reset_n(reset_n),
    .addr(addr_in_pipe[3:0]),
    .data_in(data_in_pipe),
    .write_en(cmd_valid_pipe && (cmd_in == 4'h2) && (addr_in_pipe[31:28] == 4'h0)),
    .data_out(reg_data_out)
  );

  resp_generator resp_gen_inst (
    .clk(clk),
    .reset_n(reset_n),
    .cmd_valid(cmd_valid_decoded),
    .cmd_type(cmd_type),
    .addr_valid(addr_valid),
    .data_out(data_out),
    .resp_valid(resp_valid),
    .resp_status(resp_status)
  );

  assign data_out = (addr_in_pipe == 32'hFFFF_FFF0) ? status_data_out : reg_data_out;

endmodule

// Command decoder module
module cmd_decoder (
  input wire clk,
  input wire reset_n,
  input wire [3:0] cmd_in,
  input wire cmd_valid,
  output reg [1:0] cmd_type,
  output reg cmd_valid_out
);

  localparam CMD_NOP = 4'h0;
  localparam CMD_READ = 4'h1; 
  localparam CMD_WRITE = 4'h2;
  localparam CMD_RESET = 4'h3;
  localparam CMD_STATUS = 4'h4;

  reg [3:0] cmd_in_pipe;
  reg cmd_valid_pipe;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      cmd_type <= 2'b00;
      cmd_valid_out <= 1'b0;
      cmd_in_pipe <= 4'h0;
      cmd_valid_pipe <= 1'b0;
    end else begin
      cmd_valid_out <= cmd_valid_pipe;
      cmd_in_pipe <= cmd_in;
      cmd_valid_pipe <= cmd_valid;
      if (cmd_valid_pipe) begin
        case (cmd_in_pipe)
          CMD_NOP: cmd_type <= 2'b00;
          CMD_READ: cmd_type <= 2'b01;
          CMD_WRITE: cmd_type <= 2'b10;
          CMD_RESET, CMD_STATUS: cmd_type <= 2'b11;
          default: cmd_type <= 2'b00;
        endcase
      end
    end
  end

endmodule

// Register file module
module reg_file (
  input wire clk,
  input wire reset_n,
  input wire [3:0] addr,
  input wire [31:0] data_in,
  input wire write_en,
  output reg [31:0] data_out
);

  reg [31:0] debug_regs [0:15];
  reg [3:0] addr_pipe;
  reg [31:0] data_in_pipe;
  reg write_en_pipe;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      debug_regs[0] <= 32'h0;
      debug_regs[1] <= 32'h0;
      debug_regs[2] <= 32'h0;
      debug_regs[3] <= 32'h0;
      debug_regs[4] <= 32'h0;
      debug_regs[5] <= 32'h0;
      debug_regs[6] <= 32'h0;
      debug_regs[7] <= 32'h0;
      debug_regs[8] <= 32'h0;
      debug_regs[9] <= 32'h0;
      debug_regs[10] <= 32'h0;
      debug_regs[11] <= 32'h0;
      debug_regs[12] <= 32'h0;
      debug_regs[13] <= 32'h0;
      debug_regs[14] <= 32'h0;
      debug_regs[15] <= 32'h0;
      addr_pipe <= 4'h0;
      data_in_pipe <= 32'h0;
      write_en_pipe <= 1'b0;
    end else begin
      addr_pipe <= addr;
      data_in_pipe <= data_in;
      write_en_pipe <= write_en;
      if (write_en_pipe) begin
        debug_regs[addr_pipe] <= data_in_pipe;
      end
    end
  end

  always @(*) begin
    data_out = debug_regs[addr_pipe];
  end

endmodule

// Response generator module
module resp_generator (
  input wire clk,
  input wire reset_n,
  input wire cmd_valid,
  input wire [1:0] cmd_type,
  input wire addr_valid,
  output reg [31:0] data_out,
  output reg resp_valid,
  output reg [1:0] resp_status
);

  localparam RESP_OK = 2'b00;
  localparam RESP_ERROR = 2'b01;
  localparam RESP_BUSY = 2'b10;

  reg [31:0] status_reg;
  reg cmd_valid_pipe;
  reg [1:0] cmd_type_pipe;
  reg addr_valid_pipe;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      resp_valid <= 1'b0;
      resp_status <= RESP_OK;
      status_reg <= 32'h0000_0001;
      cmd_valid_pipe <= 1'b0;
      cmd_type_pipe <= 2'b00;
      addr_valid_pipe <= 1'b0;
    end else begin
      resp_valid <= 1'b0;
      cmd_valid_pipe <= cmd_valid;
      cmd_type_pipe <= cmd_type;
      addr_valid_pipe <= addr_valid;
      if (cmd_valid_pipe) begin
        resp_valid <= 1'b1;
        case (cmd_type_pipe)
          2'b00: resp_status <= RESP_OK;
          2'b01: resp_status <= addr_valid_pipe ? RESP_OK : RESP_ERROR;
          2'b10: resp_status <= addr_valid_pipe ? RESP_OK : RESP_ERROR;
          2'b11: resp_status <= RESP_OK;
          default: resp_status <= RESP_ERROR;
        endcase
      end
    end
  end

endmodule