//SystemVerilog
// Memory array submodule
module rom_array #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] write_data,
    input write_en,
    output reg [DATA_WIDTH-1:0] read_data
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    always @(posedge clk) begin
        if (write_en) begin
            mem[addr] <= write_data;
        end
        read_data <= mem[addr];
    end
endmodule

// Programming control submodule
module prog_control #(
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16
)(
    input clk,
    input prog_en,
    input [ADDR_WIDTH-1:0] addr,
    output reg write_en
);
    reg [DEPTH-1:0] programmed;
    
    always @(posedge clk) begin
        if (prog_en && ~programmed[addr]) begin
            write_en <= 1'b1;
            programmed[addr] <= 1'b1;
        end else begin
            write_en <= 1'b0;
        end
    end
endmodule

// Top level module
module programmable_rom #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input clk,
    input prog_en,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] data
);
    wire write_en;
    
    prog_control #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) prog_ctrl (
        .clk(clk),
        .prog_en(prog_en),
        .addr(addr),
        .write_en(write_en)
    );
    
    rom_array #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) rom (
        .clk(clk),
        .addr(addr),
        .write_data(din),
        .write_en(write_en),
        .read_data(data)
    );
endmodule