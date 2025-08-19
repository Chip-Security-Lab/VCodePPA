//SystemVerilog
module tdp_ram_arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input arb_mode,
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output reg [DW-1:0] a_dout,
    input a_we, a_re,
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output reg [DW-1:0] b_dout,
    input b_we, b_re
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg arb_flag;
reg a_write_enable, b_write_enable;
reg a_read_enable, b_read_enable;

// Write control logic
always @(posedge clk) begin
    // Determine write enable signals
    a_write_enable <= a_we && (!b_we || !arb_mode || !arb_flag);
    b_write_enable <= b_we && (!a_we || arb_mode || arb_flag);
    
    // Update arb_flag based on write operations
    if (a_we && b_we && arb_mode) begin
        arb_flag <= ~arb_flag;
    end
    
    // Perform write operations
    if (a_write_enable) begin
        mem[a_addr] <= a_din;
    end
    
    if (b_write_enable) begin
        mem[b_addr] <= b_din;
    end
end

// Read control logic
always @(posedge clk) begin
    // Determine read enable signals
    a_read_enable <= a_re && (!b_re || !arb_flag);
    b_read_enable <= b_re && (!a_re || arb_flag);
    
    // Perform read operations
    if (a_read_enable) begin
        a_dout <= mem[a_addr];
    end else begin
        a_dout <= 'hz;
    end
    
    if (b_read_enable) begin
        b_dout <= mem[b_addr];
    end else begin
        b_dout <= 'hz;
    end
end

endmodule