//SystemVerilog
// Top level SRAM with parity module
module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output valid_out,
    output [DATA_BITS:0] dout
);
    wire parity_bit;
    wire parity_valid;
    
    parity_gen #(
        .DATA_BITS(DATA_BITS)
    ) parity_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(din),
        .valid_out(parity_valid),
        .parity_out(parity_bit)
    );
    
    mem_array #(
        .DATA_BITS(DATA_BITS)
    ) mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(parity_valid),
        .we(we),
        .addr(addr),
        .data_in({parity_bit, din}),
        .valid_out(valid_out),
        .data_out(dout)
    );
endmodule

// Optimized parity generator module with pipeline
module parity_gen #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    input [DATA_BITS-1:0] data_in,
    output reg valid_out,
    output reg parity_out
);
    reg [DATA_BITS-1:0] data_stage1;
    reg valid_stage1;
    
    // Combined input and parity calculation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            valid_out <= 0;
            parity_out <= 0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= valid_in;
            valid_out <= valid_stage1;
            parity_out <= ^data_stage1;
        end
    end
endmodule

// Optimized memory array module with pipeline
module mem_array #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    input we,
    input [3:0] addr,
    input [DATA_BITS:0] data_in,
    output reg valid_out,
    output reg [DATA_BITS:0] data_out
);
    reg [DATA_BITS:0] mem [0:15];
    reg [3:0] addr_stage1;
    reg [DATA_BITS:0] data_stage1;
    reg we_stage1;
    reg valid_stage1;
    
    // Combined input and memory access stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            data_stage1 <= 0;
            we_stage1 <= 0;
            valid_stage1 <= 0;
            data_out <= 0;
            valid_out <= 0;
        end else begin
            addr_stage1 <= addr;
            data_stage1 <= data_in;
            we_stage1 <= we;
            valid_stage1 <= valid_in;
            if (we_stage1) mem[addr_stage1] <= data_stage1;
            data_out <= mem[addr_stage1];
            valid_out <= valid_stage1;
        end
    end
endmodule