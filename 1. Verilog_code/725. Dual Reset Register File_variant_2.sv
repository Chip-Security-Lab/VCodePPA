//SystemVerilog
module dual_reset_regfile_pipeline #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,  // Active-low asynchronous reset
    input  wire                   sync_rst,     // Active-high synchronous reset
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0] write_addr,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [ADDR_WIDTH-1:0] read_addr,
    output reg  [DATA_WIDTH-1:0] read_data_stage1, // Registered output stage 1
    output reg  [DATA_WIDTH-1:0] read_data_stage2  // Registered output stage 2
);

    // Register array
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];
    
    // Pipeline stage 1: Read operation
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            read_data_stage1 <= {DATA_WIDTH{1'b0}};
        end
        else if (sync_rst) begin
            read_data_stage1 <= {DATA_WIDTH{1'b0}};
        end
        else begin
            read_data_stage1 <= registers[read_addr];
        end
    end

    // Pipeline stage 2: Write operation
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            read_data_stage2 <= {DATA_WIDTH{1'b0}};
            for (integer i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (sync_rst) begin
            read_data_stage2 <= {DATA_WIDTH{1'b0}};
            for (integer i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            // Write operation
            if (write_en) begin
                registers[write_addr] <= write_data;
            end
            read_data_stage2 <= read_data_stage1; // Forwarding read data to stage 2
        end
    end
endmodule