//SystemVerilog
module async_delay_buf #(parameter DW=8, DEPTH=3) (
    input logic clk, en,
    input logic [DW-1:0] data_in,
    output logic [DW-1:0] data_out
);
    // Pipeline registers for the buffer
    logic [DW-1:0] buf_reg [0:DEPTH-1];
    // Output register
    logic [DW-1:0] data_out_reg;
    
    // Split for-loop update to reduce critical path
    // Update first stage register separately
    always_ff @(posedge clk) begin
        if(en) begin
            buf_reg[0] <= data_in;
        end
    end
    
    // Pipeline the buffer updates in smaller groups to reduce path length
    genvar g;
    generate
        for(g = 1; g < DEPTH; g = g + 1) begin : update_pipeline
            always_ff @(posedge clk) begin
                if(en) begin
                    buf_reg[g] <= buf_reg[g-1];
                end
            end
        end
    endgenerate
    
    // Output stage register
    always_ff @(posedge clk) begin
        if(en) begin
            data_out_reg <= buf_reg[DEPTH-1];
        end
    end
    
    // Connect output
    assign data_out = data_out_reg;
endmodule