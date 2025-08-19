//SystemVerilog
module dual_reset_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,
    input  wire                   sync_rst,
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]  read_data
);

    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];
    wire reset_condition = !async_rst_n || sync_rst;
    
    // Read operation with optimized reset logic
    always @(*) begin
        if (reset_condition) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end else begin
            read_data <= registers[read_addr];
        end
    end
    
    // Write operation with optimized reset logic
    genvar i;
    generate
        for (i = 0; i < NUM_REGS; i = i + 1) begin : reg_init
            always @(posedge clk or negedge async_rst_n) begin
                if (!async_rst_n) begin
                    registers[i] <= {DATA_WIDTH{1'b0}};
                end else if (sync_rst) begin
                    registers[i] <= {DATA_WIDTH{1'b0}};
                end else if (write_en && (write_addr == i)) begin
                    registers[i] <= write_data;
                end
            end
        end
    endgenerate
endmodule