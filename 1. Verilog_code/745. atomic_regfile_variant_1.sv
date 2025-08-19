//SystemVerilog
module atomic_regfile #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input start,
    input [AW-1:0] addr,
    input [DW-1:0] modify_mask,
    input [DW-1:0] modify_val,
    output [DW-1:0] original_val,
    output busy
);

    wire [DW-1:0] read_value;
    wire [DW-1:0] masked_value;
    wire [AW-1:0] write_addr;
    wire [DW-1:0] write_value;

    reg [DW-1:0] mem [0:7];
    reg [2:0] state;

    assign busy = (state != 0);
    assign original_val = read_value;

    // Read Module
    read_module #(
        .DW(DW),
        .AW(AW)
    ) read_inst (
        .clk(clk),
        .start(start),
        .addr(addr),
        .mem(mem),
        .read_value(read_value),
        .state(state)
    );

    // Masking Module
    masking_module #(
        .DW(DW)
    ) mask_inst (
        .input_value(read_value),
        .modify_mask(modify_mask),
        .masked_value(masked_value)
    );

    // Write Module
    write_module #(
        .DW(DW),
        .AW(AW)
    ) write_inst (
        .clk(clk),
        .state(state),
        .addr(addr),
        .masked_value(masked_value),
        .modify_val(modify_val),
        .mem(mem)
    );

endmodule

// Read Module
module read_module #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input start,
    input [AW-1:0] addr,
    input [DW-1:0] mem [0:7],
    output reg [DW-1:0] read_value,
    output reg [2:0] state
);
    always @(posedge clk) begin
        if (start) begin
            read_value <= mem[addr];
            state <= 1;
        end
    end
endmodule

// Masking Module
module masking_module #(
    parameter DW = 64
)(
    input [DW-1:0] input_value,
    input [DW-1:0] modify_mask,
    output reg [DW-1:0] masked_value
);
    always @* begin
        masked_value = input_value & ~modify_mask;
    end
endmodule

// Write Module
module write_module #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input [2:0] state,
    input [AW-1:0] addr,
    input [DW-1:0] masked_value,
    input [DW-1:0] modify_val,
    output reg [DW-1:0] mem [0:7]
);
    always @(posedge clk) begin
        if (state == 1) begin
            mem[addr] <= masked_value | modify_val;
        end
    end
endmodule