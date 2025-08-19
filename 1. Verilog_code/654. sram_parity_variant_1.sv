//SystemVerilog
module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output reg [DATA_BITS:0] dout
);

localparam TOTAL_BITS = DATA_BITS + 1;
reg [TOTAL_BITS-1:0] mem [0:15];

// Pipeline stages
reg [3:0] addr_pipe [2:0];
reg we_pipe [2:0];
reg [DATA_BITS-1:0] din_pipe [1:0];
reg [TOTAL_BITS-1:0] write_data_pipe;
wire [TOTAL_BITS-1:0] read_data;

// Pre-calculate parity
wire parity_bit = ^din;

// Pipeline stage 1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_pipe[0] <= 4'b0;
        we_pipe[0] <= 1'b0;
        din_pipe[0] <= {DATA_BITS{1'b0}};
    end else begin
        addr_pipe[0] <= addr;
        we_pipe[0] <= we;
        din_pipe[0] <= din;
    end
end

// Pipeline stage 2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_pipe[1] <= 4'b0;
        we_pipe[1] <= 1'b0;
        din_pipe[1] <= {DATA_BITS{1'b0}};
        write_data_pipe <= {TOTAL_BITS{1'b0}};
    end else begin
        addr_pipe[1] <= addr_pipe[0];
        we_pipe[1] <= we_pipe[0];
        din_pipe[1] <= din_pipe[0];
        write_data_pipe <= {parity_bit, din_pipe[0]};
    end
end

// Memory write
always @(posedge clk) begin
    if (we_pipe[1]) begin
        mem[addr_pipe[1]] <= write_data_pipe;
    end
end

// Memory read
assign read_data = mem[addr_pipe[1]];

// Pipeline stage 3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_pipe[2] <= 4'b0;
        we_pipe[2] <= 1'b0;
        dout <= {TOTAL_BITS{1'b0}};
    end else begin
        addr_pipe[2] <= addr_pipe[1];
        we_pipe[2] <= we_pipe[1];
        dout <= read_data;
    end
end

endmodule