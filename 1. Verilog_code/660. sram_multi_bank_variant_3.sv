//SystemVerilog
module sram_multi_bank #(
    parameter BANKS = 4,
    parameter AW = 4,
    parameter DW = 16
)(
    input clk,
    input rst_n,
    input [BANKS-1:0] bank_sel,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    input valid_in,
    output ready_out,
    output [DW-1:0] dout,
    output valid_out
);

// Memory banks
reg [DW-1:0] mem [0:BANKS-1][0:(1<<AW)-1];

// Pipeline stage 1: Address decoding and bank selection
reg [BANKS-1:0] bank_sel_stage1;
reg [AW-1:0] addr_stage1;
reg we_stage1;
reg [DW-1:0] din_stage1;
reg valid_stage1;

// Pipeline stage 2: Memory access
reg [DW-1:0] bank_data [0:BANKS-1];
reg [BANKS-1:0] bank_sel_stage2;
reg valid_stage2;

// Pipeline stage 3: Data selection
reg [DW-1:0] mux_out_stage3;
reg valid_stage3;

// Stage 1: Address decoding and bank selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bank_sel_stage1 <= {BANKS{1'b0}};
        addr_stage1 <= {AW{1'b0}};
        we_stage1 <= 1'b0;
        din_stage1 <= {DW{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        bank_sel_stage1 <= bank_sel;
        addr_stage1 <= addr;
        we_stage1 <= we;
        din_stage1 <= din;
        valid_stage1 <= valid_in;
    end
end

// Stage 2: Memory access
genvar i;
generate
    for (i = 0; i < BANKS; i = i + 1) begin: bank_write
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                mem[i][addr_stage1] <= {DW{1'b0}};
            end else if (bank_sel_stage1[i] & we_stage1) begin
                mem[i][addr_stage1] <= din_stage1;
            end
        end
    end
endgenerate

// Stage 2: Memory read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bank_sel_stage2 <= {BANKS{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        bank_sel_stage2 <= bank_sel_stage1;
        valid_stage2 <= valid_stage1;
    end
end

generate
    for (i = 0; i < BANKS; i = i + 1) begin: bank_read
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                bank_data[i] <= {DW{1'b0}};
            end else begin
                bank_data[i] <= mem[i][addr_stage1];
            end
        end
    end
endgenerate

// Stage 3: Data selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mux_out_stage3 <= {DW{1'b0}};
        valid_stage3 <= 1'b0;
    end else begin
        mux_out_stage3 <= {DW{1'b0}};
        for (integer j = 0; j < BANKS; j = j + 1) begin
            if (bank_sel_stage2[j]) begin
                mux_out_stage3 <= bank_data[j];
            end
        end
        valid_stage3 <= valid_stage2;
    end
end

// Output assignments
assign dout = mux_out_stage3;
assign valid_out = valid_stage3;
assign ready_out = 1'b1; // Always ready in this implementation

endmodule