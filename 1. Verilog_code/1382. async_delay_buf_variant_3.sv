//SystemVerilog
// Top-level module
module async_delay_buf #(
    parameter DW = 8,
    parameter DEPTH = 3
)(
    input  wire         clk,
    input  wire         en,
    input  wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out
);
    // Internal signals for connecting stages
    wire [DW-1:0] stage_connections[0:DEPTH];
    
    // Map input to first stage
    assign stage_connections[0] = data_in;
    
    // Generate delay stages
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : delay_stages
            delay_stage #(
                .DW(DW)
            ) stage_inst (
                .clk(clk),
                .en(en),
                .data_in(stage_connections[i]),
                .data_out(stage_connections[i+1])
            );
        end
    endgenerate
    
    // Map final stage to output
    assign data_out = stage_connections[DEPTH];
    
endmodule

// Single-stage delay buffer
module delay_stage #(
    parameter DW = 8
)(
    input  wire         clk,
    input  wire         en,
    input  wire [DW-1:0] data_in,
    output reg  [DW-1:0] data_out
);
    
    always @(posedge clk)
        if (en)
            data_out <= data_in;
            
endmodule