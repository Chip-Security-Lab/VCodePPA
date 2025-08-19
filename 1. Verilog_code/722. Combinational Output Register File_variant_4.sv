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
    output reg [DATA_W-1:0]    read_data1,
    output reg [DATA_W-1:0]    read_data2,
    
    // Pipeline control signals
    output reg                 valid_stage1,
    output reg                 valid_stage2
);
    // Register file storage
    reg [DATA_W-1:0] regs [0:NUM_REGS-1];
    
    // Pipeline registers
    reg [ADDR_W-1:0] write_addr_stage1;
    reg [DATA_W-1:0] write_data_stage1;
    reg               write_en_stage1;
    
    // Combinational read (pipelined)
    always @(*) begin
        read_data1 = regs[read_addr1];
        read_data2 = regs[read_addr2];
    end
    
    // Stage 1: Write operation
    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < NUM_REGS; i = i + 1) begin
                regs[i] <= {DATA_W{1'b0}};
            end
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            // Pipeline stage 1
            write_addr_stage1 <= write_addr;
            write_data_stage1 <= write_data;
            write_en_stage1 <= write_en;
            valid_stage1 <= write_en;
        end
    end
    
    // Stage 2: Write operation
    always @(posedge clk) begin
        // Pipeline stage 2
        if (valid_stage1) begin
            if (write_en_stage1) begin
                regs[write_addr_stage1] <= write_data_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
endmodule