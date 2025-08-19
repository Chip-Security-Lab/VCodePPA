//SystemVerilog
// SystemVerilog
// Context bank submodule
module context_bank #(
    parameter DW = 32,
    parameter AW = 3
)(
    input clk,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output logic [DW-1:0] dout
);
    logic [DW-1:0] reg_bank [0:(1<<AW)-1];
    
    always_ff @(posedge clk) begin
        if (wr_en) reg_bank[addr] <= din;
    end
    
    assign dout = reg_bank[addr];
endmodule

// Context selector submodule
module context_selector #(
    parameter DW = 32,
    parameter CTX_BITS = 3
)(
    input [CTX_BITS-1:0] ctx_sel,
    input [DW-1:0] ctx_data [0:7],
    output logic [DW-1:0] selected_data
);
    always_comb begin
        case (ctx_sel)
            3'b000: selected_data = ctx_data[0];
            3'b001: selected_data = ctx_data[1];
            3'b010: selected_data = ctx_data[2];
            3'b011: selected_data = ctx_data[3];
            3'b100: selected_data = ctx_data[4];
            3'b101: selected_data = ctx_data[5];
            3'b110: selected_data = ctx_data[6];
            3'b111: selected_data = ctx_data[7];
            default: selected_data = {DW{1'b0}}; // Default case for safety
        endcase
    end
endmodule

// Context bank array submodule
module context_bank_array #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output logic [DW-1:0] dout
);
    // Internal signals
    logic [DW-1:0] ctx_data [0:7];
    
    // Generate 8 context banks
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ctx_banks
            context_bank #(
                .DW(DW),
                .AW(AW)
            ) ctx_bank_inst (
                .clk(clk),
                .wr_en(wr_en && (ctx_sel == i)),
                .addr(addr),
                .din(din),
                .dout(ctx_data[i])
            );
        end
    endgenerate
    
    // Context selector
    context_selector #(
        .DW(DW),
        .CTX_BITS(CTX_BITS)
    ) ctx_selector_inst (
        .ctx_sel(ctx_sel),
        .ctx_data(ctx_data),
        .selected_data(dout)
    );
endmodule

// Top-level multi-context register file
module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output logic [DW-1:0] dout
);
    // Instantiate context bank array
    context_bank_array #(
        .DW(DW),
        .AW(AW),
        .CTX_BITS(CTX_BITS)
    ) ctx_bank_array_inst (
        .clk(clk),
        .ctx_sel(ctx_sel),
        .wr_en(wr_en),
        .addr(addr),
        .din(din),
        .dout(dout)
    );
endmodule