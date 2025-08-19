//SystemVerilog
module tdp_ram_access_counter #(
    parameter DW = 24,
    parameter AW = 6
)(
    input clk, rst,
    // Port J
    input [AW-1:0] j_addr,
    input [DW-1:0] j_din,
    output reg [DW-1:0] j_dout,
    input j_we, j_oe,
    // Port K
    input [AW-1:0] k_addr,
    input [DW-1:0] k_din,
    output reg [DW-1:0] k_dout,
    input k_we, k_oe,
    // Debug interface
    output reg [31:0] j_write_count,
    output reg [31:0] j_read_count,
    output reg [31:0] k_write_count,
    output reg [31:0] k_read_count
);

(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] mem_j_buf, mem_k_buf;
reg [AW-1:0] j_addr_buf, k_addr_buf;
reg j_we_buf, j_oe_buf, k_we_buf, k_oe_buf;

// Input buffering
always @(posedge clk) begin
    if (rst) begin
        j_addr_buf <= 0;
        k_addr_buf <= 0;
        j_we_buf <= 0;
        j_oe_buf <= 0;
        k_we_buf <= 0;
        k_oe_buf <= 0;
    end else begin
        j_addr_buf <= j_addr;
        k_addr_buf <= k_addr;
        j_we_buf <= j_we;
        j_oe_buf <= j_oe;
        k_we_buf <= k_we;
        k_oe_buf <= k_oe;
    end
end

// Port J memory write operations
always @(posedge clk) begin
    if (rst) begin
        j_write_count <= 0;
    end else if (j_we_buf) begin
        mem[j_addr_buf] <= j_din;
        j_write_count <= j_write_count + 1;
    end
end

// Port J memory read operations
always @(posedge clk) begin
    if (rst) begin
        j_read_count <= 0;
        j_dout <= 0;
        mem_j_buf <= 0;
    end else if (j_oe_buf) begin
        mem_j_buf <= mem[j_addr_buf];
        j_dout <= mem_j_buf;
        j_read_count <= j_read_count + 1;
    end else begin
        j_dout <= {DW{1'b0}};
    end
end

// Port K memory write operations
always @(posedge clk) begin
    if (rst) begin
        k_write_count <= 0;
    end else if (k_we_buf) begin
        mem[k_addr_buf] <= k_din;
        k_write_count <= k_write_count + 1;
    end
end

// Port K memory read operations
always @(posedge clk) begin
    if (rst) begin
        k_read_count <= 0;
        k_dout <= 0;
        mem_k_buf <= 0;
    end else if (k_oe_buf) begin
        mem_k_buf <= mem[k_addr_buf];
        k_dout <= mem_k_buf;
        k_read_count <= k_read_count + 1;
    end else begin
        k_dout <= {DW{1'b0}};
    end
end

endmodule