//SystemVerilog
module tdp_ram_dual_clock #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 8
)(
    input clk_a,
    input [A_WIDTH-1:0] adr_a,
    input [D_WIDTH-1:0] dat_a_in,
    output reg [D_WIDTH-1:0] dat_a_out,
    input wr_a,
    input rd_a,
    
    input clk_b,
    input [A_WIDTH-1:0] adr_b,
    input [D_WIDTH-1:0] dat_b_in,
    output reg [D_WIDTH-1:0] dat_b_out,
    input wr_b,
    input rd_b
);

(* ram_style = "block" *) reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

// Port A control signals
reg [A_WIDTH-1:0] adr_a_reg;
reg [D_WIDTH-1:0] dat_a_in_reg;
reg wr_a_reg, rd_a_reg;

// Port B control signals
reg [A_WIDTH-1:0] adr_b_reg;
reg [D_WIDTH-1:0] dat_b_in_reg;
reg wr_b_reg, rd_b_reg;

// Port A address registration
always @(posedge clk_a) begin
    adr_a_reg <= adr_a;
end

// Port A data input registration
always @(posedge clk_a) begin
    dat_a_in_reg <= dat_a_in;
end

// Port A control signals registration
always @(posedge clk_a) begin
    wr_a_reg <= wr_a;
    rd_a_reg <= rd_a;
end

// Port A write operation
always @(posedge clk_a) begin
    if (wr_a_reg) begin
        mem[adr_a_reg] <= dat_a_in_reg;
    end
end

// Port A read operation
always @(posedge clk_a) begin
    if (rd_a_reg) begin
        dat_a_out <= mem[adr_a_reg];
    end
end

// Port B address registration
always @(posedge clk_b) begin
    adr_b_reg <= adr_b;
end

// Port B data input registration
always @(posedge clk_b) begin
    dat_b_in_reg <= dat_b_in;
end

// Port B control signals registration
always @(posedge clk_b) begin
    wr_b_reg <= wr_b;
    rd_b_reg <= rd_b;
end

// Port B write operation
always @(posedge clk_b) begin
    if (wr_b_reg) begin
        mem[adr_b_reg] <= dat_b_in_reg;
    end
end

// Port B read operation
always @(posedge clk_b) begin
    if (rd_b_reg) begin
        dat_b_out <= mem[adr_b_reg];
    end
end

endmodule