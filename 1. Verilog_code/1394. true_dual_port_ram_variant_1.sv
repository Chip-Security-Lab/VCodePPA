//SystemVerilog
module true_dual_port_ram #(
    parameter DW = 16,  // Data width
    parameter AW = 8    // Address width
)(
    input wire clk_a, clk_b,
    input wire [AW-1:0] addr_a, addr_b,
    input wire wr_a, wr_b,
    input wire [DW-1:0] din_a, din_b,
    output reg [DW-1:0] dout_a, dout_b
);
    // Memory array declaration with explicit size
    (* ram_style = "block" *) reg [DW-1:0] mem [(1<<AW)-1:0];
    
    // Port A operation - single cycle pipeline
    always @(posedge clk_a) begin
        if(wr_a) begin
            mem[addr_a] <= din_a;
            // Handle read-during-write on same port
            dout_a <= din_a;
        end else begin
            dout_a <= mem[addr_a];
        end
    end
    
    // Port B operation - single cycle pipeline
    always @(posedge clk_b) begin
        if(wr_b) begin
            mem[addr_b] <= din_b;
            // Handle read-during-write on same port
            dout_b <= din_b;
        end else begin
            dout_b <= mem[addr_b];
        end
    end
    
    // Memory collision handling assertions
    `ifdef SIMULATION
    always @(posedge clk_a) begin
        if (wr_a && wr_b && addr_a == addr_b && clk_a && clk_b)
            $display("WARNING: Memory collision detected at address %h", addr_a);
    end
    `endif
    
endmodule