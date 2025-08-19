//SystemVerilog
module parity_regfile_pipeline #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Write interface
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    
    // Read interface
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rd_data,
    
    // Error detection
    output wire                   parity_error
);

    // Storage for data and parity
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] parity;  // One parity bit per register

    // Pipeline registers
    reg [DATA_WIDTH-1:0] wr_data_stage1;
    reg [ADDR_WIDTH-1:0] wr_addr_stage1;
    reg wr_en_stage1;
    
    reg [DATA_WIDTH-1:0] rd_data_stage1;
    reg [ADDR_WIDTH-1:0] rd_addr_stage1;
    
    reg parity_stage1;
    
    // Calculate parity for write data (even parity: XOR of all bits should be 0)
    function bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_parity = ^data;  // XOR reduction
        end
    endfunction

    // Write operation with parity calculation (pipelined)
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
                parity[i] <= 1'b0;
            end
        end
        else begin
            // Pipeline stage 1
            wr_data_stage1 <= wr_data;
            wr_addr_stage1 <= wr_addr;
            wr_en_stage1 <= wr_en;

            // Pipeline stage 2
            if (wr_en_stage1) begin
                mem[wr_addr_stage1] <= wr_data_stage1;
                parity[wr_addr_stage1] <= calc_parity(wr_data_stage1);
            end
        end
    end
    
    // Read operation (pipelined)
    always @(posedge clk) begin
        // Pipeline stage for read address
        rd_addr_stage1 <= rd_addr;
        rd_data_stage1 <= mem[rd_addr_stage1];
    end

    // Output assignments
    assign rd_data = rd_data_stage1;
    
    // Error detection (check if current parity matches stored parity)
    assign parity_error = (calc_parity(rd_data_stage1) != parity[rd_addr_stage1]);

endmodule