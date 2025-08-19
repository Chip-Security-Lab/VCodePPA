//SystemVerilog
module byte_enable_regfile_pipeline #(
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
    output reg [DATA_WIDTH-1:0]    rdata
);
    // Memory array
    reg [DATA_WIDTH-1:0] reg_array [0:DEPTH-1];

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] wdata_stage1;
    reg [NUM_BYTES-1:0]  byte_en_stage1;
    reg                   we_stage1;

    // Valid signals for pipeline stages
    reg valid_stage1;
    reg valid_stage2;

    // Read port (asynchronous)
    always @(posedge clk) begin
        if (reset) begin
            rdata <= {DATA_WIDTH{1'b0}};
        end else if (valid_stage2) begin
            rdata <= reg_array[addr_stage1];
        end
    end

    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        if (reset) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            wdata_stage1 <= {DATA_WIDTH{1'b0}};
            byte_en_stage1 <= {NUM_BYTES{1'b0}};
            we_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            wdata_stage1 <= wdata;
            byte_en_stage1 <= byte_en;
            we_stage1 <= we;
            valid_stage1 <= 1'b1; // Mark stage as valid
        end
    end

    // Optimized subtractor implementation
    reg [DATA_WIDTH-1:0] result;
    wire [DATA_WIDTH-1:0] decremented_data;
    
    // Generate decremented data for each byte lane
    genvar i;
    generate
        for (i = 0; i < NUM_BYTES; i = i + 1) begin : byte_lanes
            assign decremented_data[i*8 +: 8] = (we_stage1 && byte_en_stage1[i]) ? 
                                               wdata_stage1[i*8 +: 8] - 8'h01 : 
                                               wdata_stage1[i*8 +: 8];
        end
    endgenerate
    
    // Select between original and decremented data
    always @(*) begin
        result = decremented_data;
    end

    // Pipeline stage 2: Write to memory with byte enable
    always @(posedge clk) begin
        if (reset) begin
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            if (we_stage1) begin
                integer j;
                for (j = 0; j < NUM_BYTES; j = j + 1) begin
                    if (byte_en_stage1[j]) begin
                        reg_array[addr_stage1][j*8 +: 8] <= result[j*8 +: 8];
                    end
                end
            end
            valid_stage2 <= 1'b1; // Mark stage as valid
        end
    end
endmodule