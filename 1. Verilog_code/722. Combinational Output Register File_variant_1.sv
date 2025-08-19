//SystemVerilog
module combo_output_regfile #(
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
    
    // Read interface (pure combinational output)
    input  wire [ADDR_W-1:0]   read_addr1,
    input  wire [ADDR_W-1:0]   read_addr2,
    output wire [DATA_W-1:0]   read_data1,
    output wire [DATA_W-1:0]   read_data2
);
    // Register file storage
    reg [DATA_W-1:0] regs [0:NUM_REGS-1];
    
    // Combinational read (direct wire assignment)
    assign read_data1 = regs[read_addr1];
    assign read_data2 = regs[read_addr2];
    
    // Reset control logic
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                regs[i] <= {DATA_W{1'b0}};
            end
        end
    end
    
    // Write control logic
    always @(posedge clk) begin
        if (!reset && write_en) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule