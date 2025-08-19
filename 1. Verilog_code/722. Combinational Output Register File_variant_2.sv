//SystemVerilog
module pipelined_output_regfile #(
    parameter DATA_W = 64,
    parameter ADDR_W = 6,
    parameter NUM_REGS = 2**ADDR_W
)(
    input  wire                clk,
    input  wire                reset,
    
    // Write interface
    input  wire                write_en,
    input  wire [ADDR_W-1:0]   write_addr,
    input  wire [DATA_W-1:0]   write_data,
    
    // Read interface
    input  wire [ADDR_W-1:0]   read_addr1,
    input  wire [ADDR_W-1:0]   read_addr2,
    output reg [DATA_W-1:0]   read_data1,
    output reg [DATA_W-1:0]   read_data2,
    
    // Pipeline control signals
    output reg                 valid_stage1,
    output reg                 valid_stage2
);

    // Register file storage
    reg [DATA_W-1:0] regs [0:NUM_REGS-1];
    
    // Stage 1: Combinational read (direct wire assignment)
    always @(*) begin
        read_data1 = regs[read_addr1];
        read_data2 = regs[read_addr2];
        valid_stage1 = 1'b1; // Indicate valid data in stage 1
    end
    
    // Stage 2: Synchronous write with reset
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            i = 0; // Initialization before the while loop
            while (i < NUM_REGS) begin
                regs[i] <= {DATA_W{1'b0}};
                i = i + 1; // Iteration step at the end of the loop
            end
            valid_stage2 <= 1'b0; // Reset valid signal
        end
        else if (write_en) begin
            regs[write_addr] <= write_data;
            valid_stage2 <= 1'b1; // Indicate valid data in stage 2
        end
    end
endmodule