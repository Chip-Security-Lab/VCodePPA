//SystemVerilog
module decoder_range #(MIN=8'h20, MAX=8'h3F) (
    input  clk,
    input  rst_n,
    input  [7:0] addr,
    output reg active
);

// Pipeline registers
reg [7:0] addr_pipe1;
reg [7:0] addr_pipe2;
reg [7:0] min_val_pipe;
reg [7:0] max_val_pipe;

// Optimized Karatsuba multiplication with pipelining
function [15:0] karatsuba_mult;
    input [7:0] a, b;
    reg [3:0] a_high, a_low, b_high, b_low;
    reg [7:0] z0, z1, z2;
    begin
        a_high = a[7:4];
        a_low = a[3:0];
        b_high = b[7:4];
        b_low = b[3:0];
        
        z0 = a_low * b_low;
        z2 = a_high * b_high;
        z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0;
        
        karatsuba_mult = (z2 << 8) + (z1 << 4) + z0;
    end
endfunction

// Pipeline stage 1: Address registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_pipe1 <= 8'h0;
    end else begin
        addr_pipe1 <= addr;
    end
end

// Pipeline stage 2: Multiplication and comparison
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_pipe2 <= 8'h0;
        min_val_pipe <= 8'h0;
        max_val_pipe <= 8'h0;
    end else begin
        addr_pipe2 <= addr_pipe1;
        min_val_pipe <= MIN;
        max_val_pipe <= MAX;
    end
end

// Pipeline stage 3: Range check
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active <= 1'b0;
    end else begin
        active <= (addr_pipe2 >= min_val_pipe) && (addr_pipe2 <= max_val_pipe);
    end
end

endmodule