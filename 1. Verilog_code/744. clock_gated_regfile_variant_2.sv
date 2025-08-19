//SystemVerilog

// Submodule for Address Decode and Clock Gating
module addr_decode_clk_gate #(
    parameter AW = 6
)(
    input clk,
    input rst_n,
    input global_en,
    input [AW-1:0] addr,
    output reg [AW-1:0] addr_out,
    output reg valid_out
);
    wire region_clk = clk & global_en & (addr[5:4] != 2'b11);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= 0;
            valid_out <= 0;
        end else begin
            addr_out <= addr;
            valid_out <= global_en;
        end
    end
endmodule

// Submodule for Memory Access
module memory_access #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input rst_n,
    input [AW-1:0] addr,
    input valid_in,
    input wr_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg valid_out
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    reg [AW-1:0] addr_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 0;
            valid_out <= 0;
            dout <= 0;
        end else if (valid_in) begin
            addr_reg <= addr;
            valid_out <= valid_in;
            if (wr_en) begin
                mem[addr] <= din;
            end
            dout <= mem[addr];
        end
    end
endmodule

// Submodule for Output Register
module output_register #(
    parameter DW = 40
)(
    input clk,
    input rst_n,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end else begin
            dout <= din;
        end
    end
endmodule

// Top-level module
module clock_gated_regfile #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input rst_n,
    input global_en,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    wire [AW-1:0] addr_stage1;
    wire valid_stage1;
    wire [DW-1:0] dout_stage2;
    wire valid_stage2;

    // Instantiate Address Decode and Clock Gate
    addr_decode_clk_gate #(.AW(AW)) addr_decode_clk_gate_inst (
        .clk(clk),
        .rst_n(rst_n),
        .global_en(global_en),
        .addr(addr),
        .addr_out(addr_stage1),
        .valid_out(valid_stage1)
    );

    // Instantiate Memory Access
    memory_access #(.DW(DW), .AW(AW)) memory_access_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr_stage1),
        .valid_in(valid_stage1),
        .wr_en(wr_en),
        .din(din),
        .dout(dout_stage2),
        .valid_out(valid_stage2)
    );

    // Instantiate Output Register
    output_register #(.DW(DW)) output_register_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(dout_stage2),
        .dout(dout)
    );

endmodule