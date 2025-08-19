//SystemVerilog
module byte_enable_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_BYTES = DATA_WIDTH/8,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    we,
    input  wire [NUM_BYTES-1:0]   byte_en,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire [DATA_WIDTH-1:0]   rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] reg_array [0:DEPTH-1];
    
    // Combinational logic for read port
    assign rdata = reg_array[addr];
    
    // Sequential logic for write port
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            for (int i = 0; i < DEPTH; i++) begin
                reg_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // Sequential logic for write operation
    always @(posedge clk) begin
        if (we) begin
            // Write with byte enable
            for (int j = 0; j < NUM_BYTES; j++) begin
                if (byte_en[j]) begin
                    reg_array[addr][j*8 +: 8] <= wdata[j*8 +: 8];
                end
            end
        end
    end

endmodule