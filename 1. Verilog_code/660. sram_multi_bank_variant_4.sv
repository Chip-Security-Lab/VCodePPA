//SystemVerilog
module sram_multi_bank #(
    parameter BANKS = 4,
    parameter AW = 4,
    parameter DW = 16
)(
    input clk,
    input [BANKS-1:0] bank_sel,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Register declarations
reg [BANKS-1:0] bank_sel_reg;
reg [AW-1:0] addr_reg;
reg [DW-1:0] din_reg;
reg we_reg;

// Input registers for timing optimization
always @(posedge clk) begin
    bank_sel_reg <= bank_sel;
    addr_reg <= addr;
    din_reg <= din;
    we_reg <= we;
end

reg [DW-1:0] mem [0:BANKS-1][0:(1<<AW)-1];
wire [BANKS-1:0] write_en;
wire [DW-1:0] bank_out [0:BANKS-1];

// Write enable generation with registered inputs
assign write_en = bank_sel_reg & {BANKS{we_reg}};

// Memory write with registered address and data
genvar i;
generate
    for (i=0; i<BANKS; i=i+1) begin : bank_write
        always @(posedge clk) begin
            if (write_en[i]) begin
                mem[i][addr_reg] <= din_reg;
            end
        end
    end
endgenerate

// Registered bank selection for read path
reg [BANKS-1:0] bank_sel_read_reg;
always @(posedge clk) begin
    bank_sel_read_reg <= bank_sel_reg;
end

// Memory read with registered bank selection
generate
    for (i=0; i<BANKS; i=i+1) begin : bank_read
        assign bank_out[i] = bank_sel_read_reg[i] ? mem[i][addr_reg] : {DW{1'b0}};
    end
endgenerate

// Multi-stage output combination with registered intermediate results
reg [DW-1:0] temp_out [0:BANKS-1];
reg [DW-1:0] final_out;

// First stage: Initial bank output
always @(posedge clk) begin
    temp_out[0] <= bank_out[0];
end

// Middle stages: Progressive combination
generate
    for (i=1; i<BANKS; i=i+1) begin : output_combine
        always @(posedge clk) begin
            temp_out[i] <= temp_out[i-1] | bank_out[i];
        end
    end
endgenerate

// Final output stage
always @(posedge clk) begin
    final_out <= |bank_sel_read_reg ? temp_out[BANKS-1] : {DW{1'b0}};
end

assign dout = final_out;

endmodule