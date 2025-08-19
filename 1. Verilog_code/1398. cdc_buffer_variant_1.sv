//SystemVerilog
// Top-level module
module cdc_buffer #(
    parameter DW = 8
) (
    input wire src_clk,
    input wire dst_clk,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    // Internal signals
    wire [DW-1:0] src_data;
    wire [DW-1:0] synchronized_data;
    
    // Source domain direct connection - removed input register
    assign src_data = din;
    
    // Synchronization stage with enhanced metastability handling
    synchronizer #(
        .DATA_WIDTH(DW)
    ) sync_inst (
        .clk(dst_clk),
        .async_data(src_data),
        .sync_data(synchronized_data)
    );
    
    // Destination domain output with additional registering
    dst_domain_capture #(
        .DATA_WIDTH(DW)
    ) dst_capture_inst (
        .clk(dst_clk),
        .data_in(synchronized_data),
        .data_out(dout)
    );
    
endmodule

// Synchronization module with enhanced metastability resolution
module synchronizer #(
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] async_data,
    output reg [DATA_WIDTH-1:0] sync_data
);
    
    // Triple-stage metastability resolution registers
    reg [DATA_WIDTH-1:0] meta_reg1;
    reg [DATA_WIDTH-1:0] meta_reg2;
    
    always @(posedge clk) begin
        // Moved the source domain register into the synchronizer first stage
        meta_reg1 <= async_data;
        meta_reg2 <= meta_reg1;
        sync_data <= meta_reg2;
    end
    
endmodule

// Destination domain output capture with optimized timing
module dst_domain_capture #(
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    
    // Additional register for improved timing margin
    reg [DATA_WIDTH-1:0] dst_buffer;
    
    always @(posedge clk) begin
        dst_buffer <= data_in;
        data_out <= dst_buffer;
    end
    
endmodule