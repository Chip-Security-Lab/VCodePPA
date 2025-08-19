//SystemVerilog
module sram_latency #(
    parameter DW = 8,
    parameter AW = 4,
    parameter LATENCY = 3
)(
    input clk,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg [0:LATENCY-1];
reg [AW-1:0] addr_reg;
reg we_reg;
reg [DW-1:0] din_reg;

// Stage 1: Input registration
always @(posedge clk) begin
    if (ce) begin
        addr_reg <= addr;
        we_reg <= we;
        din_reg <= din;
    end
end

// Stage 2: Memory access and pipeline
generate
    if (LATENCY == 1) begin
        always @(posedge clk) begin
            if (ce) begin
                if (we_reg) mem[addr_reg] <= din_reg;
                pipe_reg[0] <= mem[addr_reg];
            end
        end
    end else begin
        reg [DW-1:0] mem_out;
        
        always @(posedge clk) begin
            if (ce) begin
                if (we_reg) mem[addr_reg] <= din_reg;
                mem_out <= mem[addr_reg];
                pipe_reg[0] <= mem_out;
                
                for (int i = 1; i < LATENCY; i = i + 1) begin
                    pipe_reg[i] <= pipe_reg[i-1];
                end
            end
        end
    end
endgenerate

assign dout = pipe_reg[LATENCY-1];

endmodule