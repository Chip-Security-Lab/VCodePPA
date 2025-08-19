//SystemVerilog
module sync_reset_regfile_pipeline #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   sync_reset,   // Synchronous reset
    input  wire                   write_enable,
    input  wire [ADDR_BITS-1:0]   write_addr,
    input  wire [WIDTH-1:0]       write_data,
    input  wire [ADDR_BITS-1:0]   read_addr,
    output reg [WIDTH-1:0]       read_data,
    output reg                    valid_stage1,
    output reg                    valid_stage2
);
    // Memory storage
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Pipeline registers
    reg [ADDR_BITS-1:0] write_addr_stage1;
    reg [WIDTH-1:0]     write_data_stage1;
    reg                  write_enable_stage1;

    // Read operation (combinational)
    always @(*) begin
        read_data = memory[read_addr];
    end

    // Pipeline control logic
    always @(posedge clk) begin
        if (sync_reset) begin
            // Reset all registers synchronously
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            // Stage 1: Write operation
            write_addr_stage1 <= write_addr;
            write_data_stage1 <= write_data;
            write_enable_stage1 <= write_enable;
            valid_stage1 <= 1'b1;

            // Stage 2: Execute write
            if (write_enable_stage1) begin
                memory[write_addr_stage1] <= write_data_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
endmodule