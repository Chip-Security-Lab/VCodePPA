//SystemVerilog
// Top level module
module byte_enable_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_BYTES = DATA_WIDTH/8,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    we,
    input  wire [NUM_BYTES-1:0]    byte_en,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire [DATA_WIDTH-1:0]   rdata
);
    wire [DATA_WIDTH-1:0] merged_data;
    
    // Instance of byte enable control
    byte_enable_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_BYTES(NUM_BYTES)
    ) byte_ctrl (
        .old_data(rdata),
        .new_data(wdata),
        .byte_en(byte_en),
        .merged_data(merged_data)
    );
    
    // Instance of register array
    reg_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) reg_array_inst (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .wdata(merged_data),
        .we(we),
        .rdata(rdata)
    );
endmodule

// Memory array module
module reg_array #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    we,
    output wire [DATA_WIDTH-1:0]   rdata
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Read port
    assign rdata = mem[addr];
    
    // Write port
    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (we) begin
            mem[addr] <= wdata;
        end
    end
endmodule

// Byte enable control module
module byte_enable_ctrl #(
    parameter DATA_WIDTH = 32,
    parameter NUM_BYTES = DATA_WIDTH/8
)(
    input  wire [DATA_WIDTH-1:0]   old_data,
    input  wire [DATA_WIDTH-1:0]   new_data,
    input  wire [NUM_BYTES-1:0]    byte_en,
    output wire [DATA_WIDTH-1:0]   merged_data
);
    genvar i;
    generate
        for (i = 0; i < NUM_BYTES; i = i + 1) begin : byte_merge
            assign merged_data[i*8 +: 8] = byte_en[i] ? new_data[i*8 +: 8] : old_data[i*8 +: 8];
        end
    endgenerate
endmodule